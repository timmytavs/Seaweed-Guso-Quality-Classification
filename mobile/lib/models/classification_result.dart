class ClassificationResult {
  final int? classificationId;

  final String species;
  final double confidence;
  final String? modelName;

  final String? imageQuality;

  final String? qualityGrade;
  final String? freshness;
  final String? summary;

  final String? color;
  final String? visualTexture;
  final String? surfaceCondition;
  final String? visibleDefects;

  const ClassificationResult({
    this.classificationId,
    required this.species,
    required this.confidence,
    this.modelName,
    this.imageQuality,
    this.qualityGrade,
    this.freshness,
    this.summary,
    this.color,
    this.visualTexture,
    this.surfaceCondition,
    this.visibleDefects,
  });

  factory ClassificationResult.fromJson(
    Map<String, dynamic> json,
  ) {
    return ClassificationResult(
      classificationId: _parseInt(
        json['classification_id'],
      ),
      species: json['species']?.toString() ?? 'Unknown',
      confidence: _parseDouble(
        json['confidence'],
      ),
      modelName: json['model_name']?.toString(),
      imageQuality: json['image_quality']?.toString(),

      qualityGrade: json['quality_grade']?.toString(),
      freshness: json['freshness']?.toString(),
      summary: json['summary']?.toString(),

      color: json['color']?.toString(),
      visualTexture: json['visual_texture']?.toString(),
      surfaceCondition: json['surface_condition']?.toString(),
      visibleDefects: json['visible_defects']?.toString(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'classification_id': classificationId,
      'species': species,
      'confidence': confidence,
      'model_name': modelName,
      'image_quality': imageQuality,
      'quality_grade': qualityGrade,
      'freshness': freshness,
      'summary': summary,
      'color': color,
      'visual_texture': visualTexture,
      'surface_condition': surfaceCondition,
      'visible_defects': visibleDefects,
    };
  }

  double get confidencePercentage {
    if (confidence <= 1) {
      return confidence * 100;
    }

    return confidence;
  }

  String get formattedConfidence {
    return '${confidencePercentage.toStringAsFixed(2)}%';
  }

  bool get hasImageQuality {
    return imageQuality != null &&
        imageQuality!.trim().isNotEmpty;
  }

  bool get hasQualityGrade {
    return qualityGrade != null &&
        qualityGrade!.trim().isNotEmpty;
  }

  bool get hasFreshness {
    return freshness != null &&
        freshness!.trim().isNotEmpty;
  }

  bool get hasSummary {
    return summary != null &&
        summary!.trim().isNotEmpty;
  }

  bool get hasObservedCharacteristics {
    return hasColor ||
        hasVisualTexture ||
        hasSurfaceCondition ||
        hasVisibleDefects;
  }

  bool get hasColor {
    return color != null &&
        color!.trim().isNotEmpty;
  }

  bool get hasVisualTexture {
    return visualTexture != null &&
        visualTexture!.trim().isNotEmpty;
  }

  bool get hasSurfaceCondition {
    return surfaceCondition != null &&
        surfaceCondition!.trim().isNotEmpty;
  }

  bool get hasVisibleDefects {
    return visibleDefects != null &&
        visibleDefects!.trim().isNotEmpty;
  }

  static double _parseDouble(dynamic value) {
    if (value is double) {
      return value;
    }

    if (value is int) {
      return value.toDouble();
    }

    return double.tryParse(
          value?.toString() ?? '',
        ) ??
        0.0;
  }

  static int? _parseInt(dynamic value) {
    if (value == null) {
      return null;
    }

    if (value is int) {
      return value;
    }

    return int.tryParse(
      value.toString(),
    );
  }
}