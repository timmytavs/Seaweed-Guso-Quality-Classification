import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';

import '../models/classification_result.dart';
import '../models/selected_image.dart';
import 'auth_service.dart';

class ClassificationService {
  const ClassificationService();

  static const String _baseUrl = 'http://127.0.0.1:8000';

  // =====================================================
  // CLASSIFY IMAGE WITH JWT AUTHENTICATION
  // =====================================================

  Future<ClassificationResult> classifyImage(SelectedImage image) async {
    if (image.bytes.isEmpty) {
      throw Exception('The selected image contains no data.');
    }

    // Make sure the user is logged in.
    if (!AuthService.hasAccessToken) {
      throw Exception('Please log in before classifying an image.');
    }

    final uri = Uri.parse('$_baseUrl/classifications/');

    final request = http.MultipartRequest('POST', uri);

    // Add JWT to the request.
    request.headers.addAll(AuthService.authorizationHeaders);

    // Detect MIME type from filename.
    final contentType = _getContentType(image.fileName);

    request.files.add(
      http.MultipartFile.fromBytes(
        'file',
        image.bytes,
        filename: image.fileName,
        contentType: contentType,
      ),
    );

    // Send image to FastAPI.
    final streamedResponse = await request.send().timeout(
      const Duration(seconds: 60),
    );

    final response = await http.Response.fromStream(streamedResponse);

    // Handle expired or invalid JWT.
    if (response.statusCode == 401) {
      throw Exception(
        'Your login session is invalid or expired. '
        'Please log in again.',
      );
    }

    // Handle other API errors.
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw Exception(
        'Classification failed '
        '(${response.statusCode}): '
        '${response.body}',
      );
    }

    // Decode FastAPI response.
    final decoded = jsonDecode(response.body);

    if (decoded is! Map) {
      throw Exception('Invalid response received from backend.');
    }

    final json = Map<String, dynamic>.from(decoded);

    return ClassificationResult.fromApiResponse(json);
  }

  // =====================================================
  // DETECT IMAGE CONTENT TYPE
  // =====================================================

  MediaType _getContentType(String fileName) {
    final extension = fileName.split('.').last.toLowerCase();

    switch (extension) {
      case 'png':
        return MediaType('image', 'png');

      case 'webp':
        return MediaType('image', 'webp');

      case 'jpeg':
      case 'jpg':
      default:
        return MediaType('image', 'jpeg');
    }
  }
}
