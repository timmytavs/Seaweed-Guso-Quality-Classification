// import '../models/classification_result.dart';
// import '../models/selected_image.dart';

// class ClassificationService {
//   const ClassificationService();

//   Future<ClassificationResult> classifyImage(
//     SelectedImage image,
//   ) async {
//     // Temporary frontend simulation.
//     //
//     // This delay represents the time that will later be spent
//     // sending the image to the backend and waiting for the
//     // classification response.
//     await Future.delayed(
//       const Duration(seconds: 3),
//     );

//     // The image parameter is intentionally kept here because
//     // the real implementation will send image.bytes and
//     // image.fileName to the backend.
//     if (image.bytes.isEmpty) {
//       throw Exception(
//         'The selected image contains no data.',
//       );
//     }

//     return ClassificationResult.mock();
//   }
// }

import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';

import '../models/classification_result.dart';
import '../models/selected_image.dart';

class ClassificationService {
  const ClassificationService();

  static const String _baseUrl = 'http://127.0.0.1:8000';

  Future<ClassificationResult> classifyImage(SelectedImage image) async {
    if (image.bytes.isEmpty) {
      throw Exception('The selected image contains no data.');
    }

    final uri = Uri.parse('$_baseUrl/classifications/');

    final request = http.MultipartRequest('POST', uri);

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

    final streamedResponse = await request.send().timeout(
      const Duration(seconds: 60),
    );

    final response = await http.Response.fromStream(streamedResponse);

    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw Exception(
        'Classification failed '
        '(${response.statusCode}): '
        '${response.body}',
      );
    }

    final decoded = jsonDecode(response.body);

    if (decoded is! Map) {
      throw Exception('Invalid response received from backend.');
    }

    final json = Map<String, dynamic>.from(decoded);

    return ClassificationResult.fromApiResponse(json);
  }

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
