import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';
import 'package:image_picker/image_picker.dart';

import '../models/classification_result.dart';

enum ClassificationFailureType {
  invalidImage,
  serviceUnavailable,
  requestTimeout,
  serverError,
  unknown,
}

class ClassificationServiceException implements Exception {
  final ClassificationFailureType type;
  final String message;

  const ClassificationServiceException({
    required this.type,
    required this.message,
  });

  @override
  String toString() => message;
}

/// API integration for gUSo Mobile.
///
/// For an Android phone connected by USB with `adb reverse tcp:8000 tcp:8000`,
/// keep the default URL. For Wi-Fi testing, set GUSO_API_BASE_URL to your
/// computer's LAN address using --dart-define.
///
/// JWT is held in memory only. A persistent, secure session can be added when
/// the mobile authentication screen is connected.
class ClassificationService {
  const ClassificationService();

  static const String baseUrl = String.fromEnvironment(
    'GUSO_API_BASE_URL',
    defaultValue: 'http://127.0.0.1:8000',
  );

  static const Duration _timeout = Duration(seconds: 90);
  static String? _accessToken;

  static bool get isLoggedIn =>
      _accessToken != null && _accessToken!.isNotEmpty;

  static void clearSession() {
    _accessToken = null;
  }

  /// Check phone-to-PC networking without requiring a login.
  Future<bool> checkConnection() async {
    try {
      final response = await http
          .get(Uri.parse('$baseUrl/openapi.json'))
          .timeout(const Duration(seconds: 8));
      return response.statusCode == 200;
    } on TimeoutException {
      return false;
    } on SocketException {
      return false;
    } on http.ClientException {
      return false;
    }
  }

  /// Authenticate using the same account as gUSo Web.
  /// The future mobile login screen will call this method.
  Future<void> login({
    required String identifier,
    required String password,
  }) async {
    if (identifier.trim().isEmpty || password.isEmpty) {
      throw const ClassificationServiceException(
        type: ClassificationFailureType.serverError,
        message: 'Enter your account identifier and password.',
      );
    }

    // Never keep a previous login active when a new login is attempted.
    clearSession();

    try {
      final response = await http
          .post(
            Uri.parse('$baseUrl/auth/login'),
            headers: const {'Content-Type': 'application/json'},
            body: jsonEncode({
              'identifier': identifier.trim(),
              'password': password,
            }),
          )
          .timeout(_timeout);

      final body = _decodeObject(response.body);
      if (response.statusCode != 200) {
        throw ClassificationServiceException(
          type: ClassificationFailureType.serverError,
          message: _detailMessage(body, 'Login failed.'),
        );
      }

      final token = body['access_token'];
      if (token is! String || token.trim().isEmpty) {
        throw const ClassificationServiceException(
          type: ClassificationFailureType.serverError,
          message: 'Login succeeded, but the server returned no token.',
        );
      }

      _accessToken = token;
    } on TimeoutException {
      throw const ClassificationServiceException(
        type: ClassificationFailureType.requestTimeout,
        message: 'Login timed out. Check the connection to your PC.',
      );
    } on SocketException {
      throw const ClassificationServiceException(
        type: ClassificationFailureType.serviceUnavailable,
        message: 'Cannot reach FastAPI. Check USB debugging and adb reverse.',
      );
    } on http.ClientException {
      throw const ClassificationServiceException(
        type: ClassificationFailureType.serviceUnavailable,
        message: 'The connection to FastAPI failed.',
      );
    } on FormatException {
      throw const ClassificationServiceException(
        type: ClassificationFailureType.serverError,
        message: 'FastAPI returned an invalid login response.',
      );
    }
  }

  /// Upload a real image to the authenticated FastAPI classification route.
  Future<ClassificationResult> classifyImage(XFile image) async {
    if (image.path.trim().isEmpty) {
      throw const ClassificationServiceException(
        type: ClassificationFailureType.invalidImage,
        message: 'The selected image is invalid.',
      );
    }

    final filename = image.name;
    final lowerName = filename.toLowerCase();
    final String mimeType;
    if (lowerName.endsWith('.jpg') || lowerName.endsWith('.jpeg')) {
      mimeType = 'image/jpeg';
    } else if (lowerName.endsWith('.png')) {
      mimeType = 'image/png';
    } else {
      throw const ClassificationServiceException(
        type: ClassificationFailureType.invalidImage,
        message: 'Please select a JPG or PNG image.',
      );
    }

    final token = _requireToken();
    try {
      final request = http.MultipartRequest(
        'POST',
        Uri.parse('$baseUrl/classifications/'),
      );
      request.headers['Authorization'] = 'Bearer $token';
      request.files.add(
        await http.MultipartFile.fromPath(
          'file',
          image.path,
          filename: filename,
          contentType: MediaType.parse(mimeType),
        ),
      );

      final streamed = await request.send().timeout(_timeout);
      final response = await http.Response.fromStream(streamed).timeout(_timeout);
      final body = _decodeObject(response.body);

      if (response.statusCode == 401 || response.statusCode == 403) {
        clearSession();
        throw const ClassificationServiceException(
          type: ClassificationFailureType.serverError,
          message: 'Your session has expired. Please log in again.',
        );
      }
      if (response.statusCode != 200) {
        throw ClassificationServiceException(
          type: response.statusCode == 503
              ? ClassificationFailureType.serviceUnavailable
              : ClassificationFailureType.serverError,
          message: _detailMessage(body, 'Classification request failed.'),
        );
      }

      final rawResult = body['result'];
      if (rawResult is! Map) {
        throw const ClassificationServiceException(
          type: ClassificationFailureType.serverError,
          message: 'FastAPI returned an unexpected classification response.',
        );
      }
      final result = Map<String, dynamic>.from(rawResult);

      // The eligibility guard returns HTTP 200 with null grade and ID when
      // an image is not seaweed or is uncertain. Never show a mock grade.
      if (result['classification_id'] == null ||
          result['quality_grade'] == null) {
        throw ClassificationServiceException(
          type: ClassificationFailureType.invalidImage,
          message: _detailMessage(
            result,
            'The image could not be verified as seaweed.',
          ),
        );
      }

      // Reuse the existing mobile result class. The quality-only backend's
      // `confidence` is quality confidence, NOT species confidence.
      return ClassificationResult.fromJson({
        ...result,
        'summary': result['message'] ?? 'Classification successful.',
      });
    } on TimeoutException {
      throw const ClassificationServiceException(
        type: ClassificationFailureType.requestTimeout,
        message: 'Classification timed out. Please try again.',
      );
    } on FileSystemException {
      throw const ClassificationServiceException(
        type: ClassificationFailureType.invalidImage,
        message: 'The selected photo could not be opened.',
      );
    } on SocketException {
      throw const ClassificationServiceException(
        type: ClassificationFailureType.serviceUnavailable,
        message: 'Cannot reach the backend. Check that FastAPI is running.',
      );
    } on http.ClientException {
      throw const ClassificationServiceException(
        type: ClassificationFailureType.serviceUnavailable,
        message: 'The connection to FastAPI failed.',
      );
    } on FormatException {
      throw const ClassificationServiceException(
        type: ClassificationFailureType.serverError,
        message: 'FastAPI returned invalid JSON.',
      );
    }
  }

  /// Mark a classification as saved in shared PostgreSQL History.
  /// The existing mobile Save button will be wired to this next.
  Future<void> saveClassification(int classificationId) async {
    final token = _requireToken();
    try {
      final response = await http
          .post(
            Uri.parse('$baseUrl/classifications/$classificationId/save'),
            headers: {'Authorization': 'Bearer $token'},
          )
          .timeout(_timeout);
      if (response.statusCode == 401 || response.statusCode == 403) {
        clearSession();
        throw const ClassificationServiceException(
          type: ClassificationFailureType.serverError,
          message: 'Your session has expired. Please log in again.',
        );
      }
      if (response.statusCode != 200) {
        throw ClassificationServiceException(
          type: ClassificationFailureType.serverError,
          message: _detailMessage(
            _decodeObject(response.body),
            'Unable to save classification.',
          ),
        );
      }
    } on TimeoutException {
      throw const ClassificationServiceException(
        type: ClassificationFailureType.requestTimeout,
        message: 'Saving timed out. Please retry.',
      );
    } on SocketException {
      throw const ClassificationServiceException(
        type: ClassificationFailureType.serviceUnavailable,
        message: 'Cannot reach FastAPI while saving.',
      );
    } on http.ClientException {
      throw const ClassificationServiceException(
        type: ClassificationFailureType.serviceUnavailable,
        message: 'The connection to FastAPI failed while saving.',
      );
    } on FormatException {
      throw const ClassificationServiceException(
        type: ClassificationFailureType.serverError,
        message: 'FastAPI returned invalid JSON while saving.',
      );
    }
  }

  static String _requireToken() {
    if (!isLoggedIn) {
      throw const ClassificationServiceException(
        type: ClassificationFailureType.serverError,
        message: 'Please log in to your gUSo account before classifying.',
      );
    }
    return _accessToken!;
  }

  static Map<String, dynamic> _decodeObject(String responseBody) {
    final parsed = jsonDecode(responseBody);
    if (parsed is! Map) {
      throw const FormatException('Expected a JSON object');
    }
    return Map<String, dynamic>.from(parsed);
  }

  static String _detailMessage(
    Map<String, dynamic> body,
    String fallback,
  ) {
    final detail = body['detail'] ?? body['message'];
    if (detail is String && detail.trim().isNotEmpty) {
      return detail;
    }
    return fallback;
  }
}
