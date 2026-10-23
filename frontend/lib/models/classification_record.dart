import 'dart:typed_data';

import 'classification_result.dart';

class ClassificationRecord {
  final String id;
  final String fileName;
  final Uint8List imageBytes;
  final ClassificationResult result;
  final DateTime createdAt;

  const ClassificationRecord({
    required this.id,
    required this.fileName,
    required this.imageBytes,
    required this.result,
    required this.createdAt,
  });

  String get displayTitle {
    return '${result.qualityClass} · ${_formatTime(createdAt)}';
  }

  String get displayDate {
    return _formatDate(createdAt);
  }

  static String _formatTime(DateTime dateTime) {
    final hour = dateTime.hour;
    final minute = dateTime.minute.toString().padLeft(2, '0');

    final period = hour >= 12 ? 'PM' : 'AM';

    final twelveHour = hour == 0
        ? 12
        : hour > 12
        ? hour - 12
        : hour;

    return '$twelveHour:$minute $period';
  }

  static String _formatDate(DateTime dateTime) {
    const months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];

    return '${months[dateTime.month - 1]} ${dateTime.day}, ${dateTime.year}';
  }
}

class SavedClassificationSummary {
  final int id;
  final String qualityGrade;
  final double confidencePercentage;
  final String modelName;
  final DateTime? classifiedDate;

  // Metadata from GET /history/me. Image bytes are fetched separately
  // from the authenticated GET /history/{id}/image endpoint.
  final String? fileName;
  final bool hasImage;

  // Full JSONB classification report. Older records can have a null report.
  final Map<String, dynamic>? analysisResult;

  const SavedClassificationSummary({
    required this.id,
    required this.qualityGrade,
    required this.confidencePercentage,
    required this.modelName,
    required this.classifiedDate,
    this.fileName,
    this.hasImage = false,
    this.analysisResult,
  });

  factory SavedClassificationSummary.fromJson(Map<String, dynamic> json) {
    final rawId = json['id'];

    if (rawId is! int) {
      throw const FormatException('History record ID must be an integer.');
    }

    final rawConfidence = json['confidence'];

    if (rawConfidence is! num) {
      throw const FormatException('History confidence must be a number.');
    }

    final rawDate = json['date'];
    DateTime? date;

    if (rawDate != null) {
      if (rawDate is! String) {
        throw const FormatException('History date must be a string.');
      }

      date = DateTime.tryParse(rawDate);

      if (date == null) {
        throw const FormatException('History date has an invalid format.');
      }
    }

    // PostgreSQL JSONB is returned as a JSON object, or null for records
    // created before full report persistence was implemented.
    final rawAnalysis = json['analysis_result'];
    if (rawAnalysis != null && rawAnalysis is! Map) {
      throw const FormatException('History analysis result must be an object.');
    }

    final Map<String, dynamic>? report = rawAnalysis == null
        ? null
        : Map<String, dynamic>.from(rawAnalysis);

    final rawHasImage = json['has_image'];
    if (rawHasImage != null && rawHasImage is! bool) {
      throw const FormatException('History has_image must be a boolean.');
    }

    return SavedClassificationSummary(
      id: rawId,
      qualityGrade: json['quality_grade']?.toString() ?? 'Unknown',
      confidencePercentage: rawConfidence.toDouble(),
      modelName: json['model']?.toString() ?? 'Unknown model',
      classifiedDate: date,
      fileName: json['file_name']?.toString(),
      hasImage: rawHasImage == true,
      analysisResult: report,
    );
  }

  // These getters expose real, stored values rather than invented results.
  bool get hasFullReport =>
      analysisResult != null && analysisResult!.isNotEmpty;

  String? _reportText(String key) {
    final value = analysisResult?[key];
    if (value == null) return null;
    final text = value.toString().trim();
    return text.isEmpty ? null : text;
  }

  String? get reportedSpecies => _reportText('species');
  String? get reportedQualityGrade => _reportText('quality_grade');
  String? get reportedColor => _reportText('color');
  String? get reportedImageQuality => _reportText('image_quality');
  String? get reportedVisualTexture => _reportText('visual_texture');

  double? get reportedQualityConfidencePercentage {
    final value = analysisResult?['quality_confidence_percentage'];
    return value is num ? value.toDouble() : null;
  }

  Map<String, dynamic>? get reportedImageFeatures {
    final value = analysisResult?['image_features'];
    return value is Map ? Map<String, dynamic>.from(value) : null;
  }

  String get displayDate => classifiedDate == null
      ? 'Date unavailable'
      : ClassificationRecord._formatDate(classifiedDate!);

  String get displayTitle => '$qualityGrade · $displayDate';
}
