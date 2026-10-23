import 'classification_result.dart';

class ClassificationRecord {
  final int id;
  final String imagePath;
  final ClassificationResult result;
  final DateTime createdAt;

  const ClassificationRecord({
    required this.id,
    required this.imagePath,
    required this.result,
    required this.createdAt,
  });

  String get species => result.species;

  double get confidence => result.confidence;

  String get formattedConfidence => result.formattedConfidence;

  String? get modelName => result.modelName;

  ClassificationRecord copyWith({
    int? id,
    String? imagePath,
    ClassificationResult? result,
    DateTime? createdAt,
  }) {
    return ClassificationRecord(
      id: id ?? this.id,
      imagePath: imagePath ?? this.imagePath,
      result: result ?? this.result,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}