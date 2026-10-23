class ClassificationResult {
  // =====================================================
  // SPECIES PREDICTION (MobileNetV3 Small)
  // =====================================================

  final int? classificationId;
  final String? species;

  /// Species confidence as a percentage (for example, 98.75).
  final double confidence;
  final String modelName;
  final String message;

  // =====================================================
  // QUALITY PREDICTION (MobileNetV3 Large)
  // =====================================================

  /// One of Fresh, Regular, or Poor; null when not analyzed.
  final String? qualityGrade;

  /// Quality model confidence from 0 to 1, if supplied by the API.
  final double? qualityConfidence;

  /// Quality model confidence from 0 to 100, if available.
  final double? qualityConfidencePercentage;

  // Keep these properties for existing Flutter result widgets.
  final String qualityClass;
  final String qualityLabel;

  final String commonName;
  final String? scientificName;
  final String localName;

  final String freshnessLevel;
  final String imageQuality;
  final String color;
  final String visualTexture;
  final String surfaceCondition;
  final String visibleDefects;
  final String summary;

  const ClassificationResult({
    this.classificationId,
    this.species,
    required this.confidence,
    required this.modelName,
    required this.message,
    this.qualityGrade,
    this.qualityConfidence,
    this.qualityConfidencePercentage,
    required this.qualityClass,
    required this.qualityLabel,
    required this.commonName,
    this.scientificName,
    required this.localName,
    required this.freshnessLevel,
    required this.imageQuality,
    required this.color,
    required this.visualTexture,
    required this.surfaceCondition,
    required this.visibleDefects,
    required this.summary,
  });

  // =====================================================
  // PARSE THE NESTED FASTAPI RESPONSE
  // =====================================================

  factory ClassificationResult.fromApiResponse(Map<String, dynamic> json) {
    final dynamic rawResult = json['result'];

    if (rawResult is! Map<String, dynamic>) {
      throw const FormatException(
        'Invalid classification response from server.',
      );
    }

    final String? detectedSpecies = rawResult['species']?.toString();
    final double speciesConfidencePercentage =
        (rawResult['confidence_percentage'] as num?)?.toDouble() ?? 0.0;
    final String backendMessage =
        rawResult['message']?.toString() ?? 'Classification completed.';
    final String model =
        rawResult['model_name']?.toString() ?? 'Unknown model';
    final int? id = (rawResult['classification_id'] as num?)?.toInt();

    final String? gradeFromApi = rawResult['quality_grade']?.toString().trim();
    final String? grade =
        (gradeFromApi == null || gradeFromApi.isEmpty) ? null : gradeFromApi;

    final double? qualityConfidence =
        (rawResult['quality_confidence'] as num?)?.toDouble();
    final double? qualityConfidencePercentage =
        (rawResult['quality_confidence_percentage'] as num?)?.toDouble() ??
        (qualityConfidence == null ? null : qualityConfidence * 100);

    // These are image-level measurements from the optional processing
    // modules. They describe the photograph, including its background,
    // rather than independently determining seaweed health or freshness.
    String readImageFeature(String key) {
      final value = rawResult[key];
      if (value == null) return 'Not analyzed';
      final text = value.toString().trim();
      return text.isEmpty ? 'Not analyzed' : text;
    }

    final String dominantColor = readImageFeature('color');
    final String photographicImageQuality = readImageFeature('image_quality');
    final String visibleTexture = readImageFeature('visual_texture');

    // The existing UI uses qualityClass and qualityLabel. Feed those
    // widgets the model's actual quality grade, not a fabricated A/B/C grade.
    final String qualityClass = grade ?? 'Not available';
    final String qualityLabel =
        grade == null ? 'Quality not analyzed' : '$grade quality';

    final String summary;
    if (detectedSpecies == null) {
      summary = backendMessage;
    } else if (grade == null) {
      summary =
          'The species model classified this image as $detectedSpecies '
          'with ${speciesConfidencePercentage.toStringAsFixed(2)}% '
          'confidence. Quality was not analyzed.';
    } else {
      final String qualityDetails = qualityConfidencePercentage == null
          ? 'The quality model predicted $grade.'
          : 'The quality model predicted $grade with '
                '${qualityConfidencePercentage.toStringAsFixed(2)}% '
                'confidence.';

      summary =
          'The species model classified this image as $detectedSpecies '
          'with ${speciesConfidencePercentage.toStringAsFixed(2)}% '
          'confidence. $qualityDetails';
    }

    return ClassificationResult(
      classificationId: id,
      species: detectedSpecies,
      confidence: speciesConfidencePercentage,
      modelName: model,
      message: backendMessage,
      qualityGrade: grade,
      qualityConfidence: qualityConfidence,
      qualityConfidencePercentage: qualityConfidencePercentage,
      qualityClass: qualityClass,
      qualityLabel: qualityLabel,
      commonName: detectedSpecies ?? 'Unknown',
      scientificName: null,
      localName: detectedSpecies ?? 'Unknown',
      // Freshness, biological surface condition, and defects are not
      // measured by these models or the current image-processing modules.
      freshnessLevel: 'Not separately analyzed',
      imageQuality: photographicImageQuality,
      color: dominantColor,
      visualTexture: visibleTexture,
      surfaceCondition: 'Not analyzed',
      visibleDefects: 'Not analyzed',
      summary: summary,
    );
  }

  // Keep the existing mock factory for UI previews and older code.
  factory ClassificationResult.mock() {
    return const ClassificationResult(
      classificationId: null,
      species: 'KAPPAPHYCUS',
      confidence: 94.0,
      modelName: 'Mock',
      message: 'Frontend mock result.',
      qualityClass: 'Class A',
      qualityLabel: 'High Quality',
      commonName: 'Guso',
      scientificName: 'Eucheuma denticulatum',
      localName: 'Guso',
      freshnessLevel: 'Fresh',
      imageQuality: 'Clear',
      color: 'Healthy green coloration',
      visualTexture: 'Firm-looking and intact',
      surfaceCondition: 'Clean surface with minimal discoloration',
      visibleDefects: 'No significant visible defects',
      summary:
          'The uploaded Guso image shows visual characteristics '
          'associated with high-quality and fresh seaweed.',
    );
  }
}
