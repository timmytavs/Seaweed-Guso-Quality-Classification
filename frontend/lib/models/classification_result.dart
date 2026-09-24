// class ClassificationResult {
//   final String qualityClass;
//   final String qualityLabel;
//   final double confidence;

//   final String commonName;
//   final String? scientificName;
//   final String localName;

//   final String freshnessLevel;
//   final String imageQuality;

//   final String color;
//   final String visualTexture;
//   final String surfaceCondition;
//   final String visibleDefects;

//   final String summary;

//   const ClassificationResult({
//     required this.qualityClass,
//     required this.qualityLabel,
//     required this.confidence,
//     required this.commonName,
//     this.scientificName,
//     required this.localName,
//     required this.freshnessLevel,
//     required this.imageQuality,
//     required this.color,
//     required this.visualTexture,
//     required this.surfaceCondition,
//     required this.visibleDefects,
//     required this.summary,
//   });

//   /// Temporary frontend-only result.
//   ///
//   /// This will eventually be replaced by data returned
//   /// by the real classification backend.
//   factory ClassificationResult.mock() {
//     return const ClassificationResult(
//       qualityClass: 'Class A',
//       qualityLabel: 'High Quality',
//       confidence: 94.0,
//       commonName: 'Guso',
//       scientificName: 'Eucheuma denticulatum',
//       localName: 'Guso',
//       freshnessLevel: 'Fresh',
//       imageQuality: 'Clear',
//       color: 'Healthy green coloration',
//       visualTexture: 'Firm-looking and intact',
//       surfaceCondition: 'Clean surface with minimal discoloration',
//       visibleDefects: 'No significant visible defects',
//       summary:
//           'The uploaded Guso image shows visual characteristics associated '
//           'with high-quality and fresh seaweed.',
//     );
//   }
// }

class ClassificationResult {
  // =====================================================
  // REAL BACKEND DATA
  // =====================================================

  final int? classificationId;

  /// Current AI prediction.
  /// Example: KAPPAPHYCUS
  final String? species;

  /// Confidence percentage.
  /// Example: 98.75
  final double confidence;

  final String modelName;

  final String message;

  // =====================================================
  // FUTURE QUALITY CLASSIFICATION DATA
  // =====================================================
  //
  // These fields are retained because your current
  // frontend widgets already use them.
  //
  // The current AI does NOT provide these values yet.
  // =====================================================

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
  // CREATE RESULT FROM FASTAPI RESPONSE
  // =====================================================

  factory ClassificationResult.fromApiResponse(Map<String, dynamic> json) {
    final dynamic rawResult = json['result'];

    if (rawResult is! Map<String, dynamic>) {
      throw const FormatException(
        'Invalid classification response from server.',
      );
    }

    final String? detectedSpecies = rawResult['species']?.toString();

    final double confidencePercentage =
        (rawResult['confidence_percentage'] as num?)?.toDouble() ?? 0.0;

    final String backendMessage =
        rawResult['message']?.toString() ?? 'Classification completed.';

    final String model = rawResult['model_name']?.toString() ?? 'Unknown model';

    final int? id = (rawResult['classification_id'] as num?)?.toInt();

    return ClassificationResult(
      classificationId: id,

      species: detectedSpecies,

      confidence: confidencePercentage,

      modelName: model,

      message: backendMessage,

      // -------------------------------------------------
      // QUALITY DATA
      // -------------------------------------------------
      // Current model cannot determine these yet.
      // Do not generate fake quality results.
      // -------------------------------------------------
      qualityClass: 'Not available',

      qualityLabel: 'Quality not analyzed',

      commonName: detectedSpecies ?? 'Unknown',

      scientificName: null,

      localName: detectedSpecies ?? 'Unknown',

      freshnessLevel: 'Not analyzed',

      imageQuality: 'Not analyzed',

      color: 'Not analyzed',

      visualTexture: 'Not analyzed',

      surfaceCondition: 'Not analyzed',

      visibleDefects: 'Not analyzed',

      summary: detectedSpecies != null
          ? 'The uploaded image was classified as '
                '$detectedSpecies with '
                '${confidencePercentage.toStringAsFixed(2)}% '
                'confidence. Quality grading has not been '
                'implemented yet.'
          : backendMessage,
    );
  }

  // =====================================================
  // OLD MOCK RESULT
  // =====================================================
  //
  // Keep this temporarily so nothing else in the frontend
  // breaks while we connect the backend.
  // =====================================================

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
