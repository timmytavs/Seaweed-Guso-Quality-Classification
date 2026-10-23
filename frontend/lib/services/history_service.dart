import 'dart:convert';
import 'dart:typed_data';

import 'package:http/http.dart' as http;

import 'auth_service.dart';

class HistoryService {
  const HistoryService();

  static const String _baseUrl = 'http://127.0.0.1:8000';

  // =====================================================
  // FETCH SAVED HISTORY FROM POSTGRESQL
  // =====================================================

  Future<List<Map<String, dynamic>>> fetchSavedHistory() async {
    // Check if a JWT is available.
    if (!AuthService.hasAccessToken) {
      throw Exception('Please log in to view your classification history.');
    }

    final uri = Uri.parse('$_baseUrl/history/me');

    // Send authenticated request.
    final response = await http
        .get(uri, headers: AuthService.authorizationHeaders)
        .timeout(const Duration(seconds: 30));

    // =====================================================
    // HANDLE AUTHENTICATION ERRORS
    // =====================================================

    if (response.statusCode == 401) {
      throw Exception(
        'Your login session has expired or is invalid. '
        'Please log in again.',
      );
    }

    if (response.statusCode == 403) {
      throw Exception('You do not have permission to access this history.');
    }

    // =====================================================
    // HANDLE OTHER API ERRORS
    // =====================================================

    if (response.statusCode != 200) {
      throw Exception(
        'Unable to load classification history '
        '(HTTP ${response.statusCode}).',
      );
    }

    // =====================================================
    // PARSE BACKEND RESPONSE
    // =====================================================

    final dynamic decoded = jsonDecode(response.body);

    if (decoded is! Map<String, dynamic>) {
      throw const FormatException(
        'Invalid history response received from the server.',
      );
    }

    final dynamic records = decoded['records'];

    if (records is! List) {
      throw const FormatException(
        'The history response does not contain a valid records list.',
      );
    }

    // Convert JSON records to Dart maps.
    return records
        .map<Map<String, dynamic>>((item) {
          if (item is! Map) {
            throw const FormatException('Invalid classification record.');
          }

          return Map<String, dynamic>.from(item);
        })
        .toList(growable: false);
  }

  // =====================================================
  // FETCH ORIGINAL IMAGE OF AN OWNED, SAVED CLASSIFICATION
  // =====================================================

  Future<Uint8List> fetchSavedImage(int classificationId) async {
    if (classificationId <= 0) {
      throw ArgumentError.value(
        classificationId,
        'classificationId',
        'Must be a positive database classification ID.',
      );
    }

    if (!AuthService.hasAccessToken) {
      throw Exception('Please log in to view this saved image.');
    }

    final uri = Uri.parse(
      '$_baseUrl/history/$classificationId/image',
    );

    final response = await http
        .get(uri, headers: AuthService.authorizationHeaders)
        .timeout(const Duration(seconds: 30));

    if (response.statusCode == 401) {
      throw Exception(
        'Your login session has expired or is invalid. '
        'Please log in again.',
      );
    }

    if (response.statusCode == 403) {
      throw Exception('You do not have permission to view this image.');
    }

    if (response.statusCode == 404) {
      throw Exception('This saved image is unavailable.');
    }

    if (response.statusCode == 415) {
      throw Exception('The saved image format is not supported.');
    }

    if (response.statusCode != 200) {
      throw Exception(
        'Unable to load saved image (HTTP ${response.statusCode}).',
      );
    }

    final contentType = response.headers['content-type']
            ?.split(';')
            .first
            .trim()
            .toLowerCase() ??
        '';

    if (contentType != 'image/jpeg' && contentType != 'image/png') {
      throw const FormatException(
        'The server did not return a supported image.',
      );
    }

    if (response.bodyBytes.isEmpty) {
      throw const FormatException('The saved image is empty.');
    }

    return response.bodyBytes;
  }
}
