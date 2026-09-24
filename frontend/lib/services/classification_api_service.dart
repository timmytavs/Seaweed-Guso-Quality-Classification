import 'dart:convert';
import 'dart:typed_data';

import 'package:http/http.dart' as http;

class ClassificationApiService {
  static const String baseUrl = 'http://127.0.0.1:8000';

  static Future<Map<String, dynamic>> classifyImage({
    required Uint8List imageBytes,
    required String fileName,
  }) async {
    final uri = Uri.parse('$baseUrl/classifications/');

    final request = http.MultipartRequest('POST', uri);

    request.files.add(
      http.MultipartFile.fromBytes('file', imageBytes, filename: fileName),
    );

    final streamedResponse = await request.send();

    final response = await http.Response.fromStream(streamedResponse);

    if (response.statusCode >= 200 && response.statusCode < 300) {
      return jsonDecode(response.body);
    }

    throw Exception(
      'Classification failed: '
      '${response.statusCode} ${response.body}',
    );
  }
}
