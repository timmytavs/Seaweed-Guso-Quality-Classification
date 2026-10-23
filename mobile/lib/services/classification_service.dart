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

class ClassificationService {
  const ClassificationService();

  Future<ClassificationResult> classifyImage(XFile image) async {
    if (image.path.trim().isEmpty) {
      throw const ClassificationServiceException(
        type: ClassificationFailureType.invalidImage,
        message: 'The selected image is invalid.',
      );
    }

    // Temporary analyzing delay.
    await Future.delayed(
      const Duration(seconds: 2),
    );

    // Temporary mock result.
    // Replace this with the real backend request once
    // POST /api/classify is available.
    return const ClassificationResult(
      classificationId: 1,
      species: 'Caulerpa lentillifera',
      confidence: 94.0,
      modelName: 'MobileNetV3',

      imageQuality: 'Clear',
      qualityGrade: 'Class A — High Quality',
      freshness: 'Fresh',

      summary:
          'The uploaded seaweed image shows visual characteristics associated '
          'with high-quality and fresh seaweed.',

      color: 'Healthy green coloration',
      visualTexture: 'Firm-looking and intact',
      surfaceCondition: 'Clean surface with minimal discoloration',
      visibleDefects: 'No significant visible defects',
    );
  }
}