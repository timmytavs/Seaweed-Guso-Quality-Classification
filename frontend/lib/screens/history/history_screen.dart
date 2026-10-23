import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../app/theme.dart';
import '../../models/classification_record.dart';
import '../../providers/classification_provider.dart';
import '../../services/history_service.dart';
import '../../widgets/classification/characteristics_panel.dart';
import '../../widgets/classification/classification_summary.dart';

// A merged item for the UI. Full records belong to the current Flutter
// session; summaries are independently loaded from PostgreSQL.
class _HistoryEntry {
  final String id;
  final ClassificationRecord? record;
  final SavedClassificationSummary? summary;

  _HistoryEntry.full(ClassificationRecord full)
    : id = full.id,
      record = full,
      summary = null;

  _HistoryEntry.saved(SavedClassificationSummary saved)
    : id = saved.id.toString(),
      record = null,
      summary = saved;

  String get grade => record?.result.qualityClass ?? summary!.qualityGrade;
  String get date => record?.displayDate ?? summary!.displayDate;
  String get subtitle => record?.fileName ?? 'Saved record #$id';

  // Locally saved results have full in-memory details. Older PostgreSQL
  // records may only have the original summary and photograph.
  bool get hasDetailedReport => record != null || summary!.hasFullReport;
  String get statusLabel => record != null
      ? 'Current session'
      : summary!.hasFullReport
          ? 'Complete report'
          : 'Summary only';
}

class HistoryScreen extends StatefulWidget {
  const HistoryScreen({super.key});

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  static const double _historyBreakpoint = 900;
  String? _selectedId;

  @override
  void initState() {
    super.initState();
    // The provider notifies listeners. Load after the first build, not
    // synchronously while the widget tree is building.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        context.read<ClassificationProvider>().loadSavedHistory();
      }
    });
  }

  void _select(_HistoryEntry entry) {
    setState(() {
      _selectedId = entry.id;
    });
    if (entry.record != null) {
      context.read<ClassificationProvider>().selectRecord(entry.record!);
    }
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<ClassificationProvider>();
    final localRecords = provider.records;
    final idsWithFullData = localRecords.map((record) => record.id).toSet();

    // Same server ID can exist in both lists. Favor the in-session entry
    // because it has actual uploaded bytes and the complete AI result.
    final entries = <_HistoryEntry>[
      ...localRecords.map(_HistoryEntry.full),
      ...provider.savedSummaries
          .where((summary) => !idsWithFullData.contains(summary.id.toString()))
          .map(_HistoryEntry.saved),
    ];

    final activeId = entries.any((entry) => entry.id == _selectedId)
        ? _selectedId
        : entries.any((entry) => entry.id == provider.selectedRecord?.id)
        ? provider.selectedRecord?.id
        : entries.isEmpty
        ? null
        : entries.first.id;
    final selected = activeId == null
        ? null
        : entries.firstWhere((entry) => entry.id == activeId);

    return Column(
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          color: AppColors.sidebar,
          child: Row(
            children: [
              const Icon(Icons.history_rounded, color: AppColors.primary),
              const SizedBox(width: 10),
              const Expanded(
                child: Text(
                  'Classification History',
                  style: TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              if (provider.isLoadingHistory)
                const Padding(
                  padding: EdgeInsets.only(right: 12),
                  child: SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                ),
              IconButton(
                tooltip: 'Refresh saved history',
                onPressed: provider.isLoadingHistory
                    ? null
                    : () => context
                          .read<ClassificationProvider>()
                          .loadSavedHistory(),
                icon: const Icon(Icons.refresh_rounded),
                color: AppColors.primary,
              ),
            ],
          ),
        ),
        if (provider.historyError != null)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            color: AppColors.surfaceDark,
            child: Row(
              children: [
                const Icon(Icons.error_outline, color: AppColors.error),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    provider.historyError!,
                    style: const TextStyle(color: AppColors.textPrimary),
                  ),
                ),
              ],
            ),
          ),
        Expanded(
          child: entries.isEmpty && provider.isLoadingHistory
              ? const Center(child: CircularProgressIndicator())
              : entries.isEmpty
              ? const _EmptyHistoryView()
              : LayoutBuilder(
                  builder: (context, constraints) {
                    // Non-empty entry list guarantees a selected record.
                    final chosen = selected!;
                    final isWide = constraints.maxWidth >= _historyBreakpoint;
                    final list = _HistoryList(
                      entries: entries,
                      selectedId: chosen.id,
                      onSelect: _select,
                      compact: !isWide,
                    );
                    final details = chosen.record != null
                        ? _HistoryDetails(
                            record: chosen.record!,
                            useInternalScroll: isWide,
                          )
                        : _SavedSummaryDetails(
                            summary: chosen.summary!,
                            useInternalScroll: isWide,
                          );

                    if (isWide) {
                      return Row(
                        children: [
                          SizedBox(width: 280, child: list),
                          Container(width: 1, color: AppColors.disabled),
                          Expanded(child: details),
                        ],
                      );
                    }

                    return SingleChildScrollView(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          list,
                          Container(height: 1, color: AppColors.disabled),
                          details,
                        ],
                      ),
                    );
                  },
                ),
        ),
      ],
    );
  }
}

class _HistoryList extends StatelessWidget {
  final List<_HistoryEntry> entries;
  final String selectedId;
  final ValueChanged<_HistoryEntry> onSelect;
  final bool compact;

  const _HistoryList({
    required this.entries,
    required this.selectedId,
    required this.onSelect,
    required this.compact,
  });

  @override
  Widget build(BuildContext context) {
    final detailedCount = entries.where((entry) => entry.hasDetailedReport).length;
    final summaryOnlyCount = entries.length - detailedCount;

    final content = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.fromLTRB(20, 22, 20, 8),
          child: Text(
            'Saved Records',
            style: TextStyle(
              color: AppColors.textPrimary,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Text(
            '${entries.length} saved classification${entries.length == 1 ? '' : 's'}',
            style: const TextStyle(color: AppColors.textMuted, fontSize: 12),
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 5, 20, 0),
          child: Text(
            '$detailedCount with detailed results · $summaryOnlyCount summary only',
            style: const TextStyle(color: AppColors.textSecondary, fontSize: 11),
          ),
        ),
        const SizedBox(height: 16),
        if (compact)
          SizedBox(
            height: 130,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              itemCount: entries.length,
              separatorBuilder: (_, _) => const SizedBox(width: 8),
              itemBuilder: (context, index) {
                final entry = entries[index];
                return SizedBox(
                  width: 220,
                  child: _HistoryListItem(
                    entry: entry,
                    isSelected: entry.id == selectedId,
                    onTap: () => onSelect(entry),
                  ),
                );
              },
            ),
          )
        else
          Expanded(
            child: ListView.separated(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              itemCount: entries.length,
              separatorBuilder: (_, _) => const SizedBox(height: 8),
              itemBuilder: (context, index) {
                final entry = entries[index];
                return _HistoryListItem(
                  entry: entry,
                  isSelected: entry.id == selectedId,
                  onTap: () => onSelect(entry),
                );
              },
            ),
          ),
      ],
    );

    return Container(
      width: double.infinity,
      color: AppColors.sidebar,
      child: compact
          ? Padding(padding: const EdgeInsets.only(bottom: 12), child: content)
          : content,
    );
  }
}

class _HistoryListItem extends StatelessWidget {
  final _HistoryEntry entry;
  final bool isSelected;
  final VoidCallback onTap;

  const _HistoryListItem({
    required this.entry,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: isSelected ? AppColors.primaryDark : AppColors.surfaceDark,
      borderRadius: BorderRadius.circular(AppRadius.medium),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppRadius.medium),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(AppRadius.small),
                child: SizedBox(
                  width: 52,
                  height: 52,
                  child:
                      entry.record != null &&
                          entry.record!.imageBytes.isNotEmpty
                      ? Image.memory(
                          entry.record!.imageBytes,
                          fit: BoxFit.cover,
                        )
                      : Container(
                          color: AppColors.surface,
                          child: const Icon(
                            Icons.description_outlined,
                            color: AppColors.primary,
                          ),
                        ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      entry.grade,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: isSelected
                            ? AppColors.primary
                            : AppColors.textPrimary,
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      entry.date,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: AppColors.textMuted,
                        fontSize: 11,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      entry.subtitle,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 11,
                      ),
                    ),
                    const SizedBox(height: 8),
                    _ReportStatusChip(
                      label: entry.statusLabel,
                      detailed: entry.hasDetailedReport,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// Explicitly distinguish current-session, stored full reports, and legacy
// summary-only records without pretending that missing values were measured.
class _ReportStatusChip extends StatelessWidget {
  final String label;
  final bool detailed;

  const _ReportStatusChip({required this.label, required this.detailed});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
      decoration: BoxDecoration(
        color: detailed ? AppColors.primaryDark : AppColors.surfaceDark,
        borderRadius: BorderRadius.circular(AppRadius.small),
        border: Border.all(
          color: detailed ? AppColors.primary : AppColors.disabled,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            detailed ? Icons.check_circle_outline : Icons.info_outline,
            color: detailed ? AppColors.primary : AppColors.textSecondary,
            size: 13,
          ),
          const SizedBox(width: 5),
          Flexible(
            child: Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: detailed ? AppColors.primary : AppColors.textSecondary,
                fontSize: 10,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SavedSummaryDetails extends StatelessWidget {
  final SavedClassificationSummary summary;
  final bool useInternalScroll;

  const _SavedSummaryDetails({
    required this.summary,
    this.useInternalScroll = true,
  });

  @override
  Widget build(BuildContext context) {
    final content = Padding(
      padding: const EdgeInsets.all(28),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(AppRadius.large),
              border: Border.all(color: AppColors.borderPrimary, width: 1.5),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Row(
                  children: [
                    Icon(Icons.cloud_done_outlined, color: AppColors.primary),
                    SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'Saved Classification Record',
                        style: TextStyle(
                          color: AppColors.textPrimary,
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Text(
                  'Record #${summary.id} · ${summary.displayDate}',
                  style: const TextStyle(color: AppColors.textSecondary),
                ),
                const SizedBox(height: 12),
                _ReportStatusChip(
                  label: summary.hasFullReport ? 'Complete report' : 'Summary only',
                  detailed: summary.hasFullReport,
                ),
                const SizedBox(height: 24),
                _SummaryField(
                  label: 'Quality Grade',
                  value: summary.reportedQualityGrade ?? summary.qualityGrade,
                  icon: Icons.star_outline_rounded,
                ),
                _SummaryField(
                  label: 'Species Confidence',
                  value: '${summary.confidencePercentage.toStringAsFixed(2)}%',
                  icon: Icons.analytics_outlined,
                ),
                _SummaryField(
                  label: 'Species Model',
                  value: summary.modelName,
                  icon: Icons.memory_rounded,
                ),
                _SummaryField(
                  label: 'Date',
                  value: summary.displayDate,
                  icon: Icons.calendar_today_outlined,
                ),
                if (summary.fileName != null && summary.fileName!.isNotEmpty)
                  _SummaryField(
                    label: 'Original File',
                    value: summary.fileName!,
                    icon: Icons.image_outlined,
                  ),
                const Divider(color: AppColors.disabled),
                const SizedBox(height: 16),
                const Padding(
                  padding: EdgeInsets.only(bottom: 18),
                  child: Text(
                    'Stored AI Analysis',
                    style: TextStyle(
                      color: AppColors.textPrimary,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                if (summary.hasFullReport) ...[
                  if (summary.reportedSpecies != null)
                    _SummaryField(
                      label: 'Detected Species',
                      value: summary.reportedSpecies!,
                      icon: Icons.eco_outlined,
                    ),
                  if (summary.reportedQualityConfidencePercentage != null)
                    _SummaryField(
                      label: 'Quality Confidence',
                      value: '${summary.reportedQualityConfidencePercentage!.toStringAsFixed(2)}%',
                      icon: Icons.verified_outlined,
                    ),
                  if (summary.reportedColor != null)
                    _SummaryField(
                      label: 'Dominant Color',
                      value: summary.reportedColor!,
                      icon: Icons.palette_outlined,
                    ),
                  if (summary.reportedImageQuality != null)
                    _SummaryField(
                      label: 'Photographic Quality',
                      value: summary.reportedImageQuality!,
                      icon: Icons.photo_camera_outlined,
                    ),
                  if (summary.reportedVisualTexture != null)
                    _SummaryField(
                      label: 'Visual Texture',
                      value: summary.reportedVisualTexture!,
                      icon: Icons.grain_outlined,
                    ),
                  if (summary.analysisResult?['message'] is String)
                    _SummaryField(
                      label: 'Classification Message',
                      value: summary.analysisResult!['message'] as String,
                      icon: Icons.info_outline,
                    ),
                  if (summary.reportedImageFeatures != null) ...[
                    const SizedBox(height: 10),
                    _SavedMeasurementsPanel(
                      features: summary.reportedImageFeatures!,
                    ),
                  ],
                ] else
                  const _SummaryOnlyReportNotice(),
              ],
            ),
          ),
          const SizedBox(height: 24),
          const _HistoryImageHeading(),
          const SizedBox(height: 12),
          if (summary.hasImage)
            _SavedImagePreview(classificationId: summary.id)
          else
            const _ImageUnavailableNotice(),
        ],
      ),
    );

    return useInternalScroll ? SingleChildScrollView(child: content) : content;
  }
}

// Keep the "Stored AI Analysis" section visible for older records too.
// Explain the missing fields instead of fabricating confidence or features.
class _SummaryOnlyReportNotice extends StatelessWidget {
  const _SummaryOnlyReportNotice();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surfaceDark,
        borderRadius: BorderRadius.circular(AppRadius.medium),
        border: Border.all(color: AppColors.disabled),
      ),
      child: const Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.info_outline, color: AppColors.textSecondary, size: 22),
          SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Detailed analysis not stored',
                  style: TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                SizedBox(height: 7),
                Text(
                  'This classification predates full report storage. '
                  'Its saved quality grade, species confidence, model, '
                  'date, and original image remain available. To obtain '
                  'a new detailed report, classify the photograph again.',
                  style: TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 13,
                    height: 1.5,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _HistoryImageHeading extends StatelessWidget {
  const _HistoryImageHeading();

  @override
  Widget build(BuildContext context) {
    return const Row(
      children: [
        Icon(Icons.image_outlined, color: AppColors.primary, size: 22),
        SizedBox(width: 10),
        Expanded(
          child: Text(
            'Original Image',
            style: TextStyle(
              color: AppColors.textPrimary,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ],
    );
  }
}

class _ImageUnavailableNotice extends StatelessWidget {
  const _ImageUnavailableNotice();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.surfaceDark,
        borderRadius: BorderRadius.circular(AppRadius.large),
        border: Border.all(color: AppColors.disabled),
      ),
      child: const Row(
        children: [
          Icon(Icons.image_not_supported_outlined, color: AppColors.textMuted),
          SizedBox(width: 12),
          Expanded(
            child: Text(
              'No original image is stored for this classification.',
              style: TextStyle(color: AppColors.textSecondary),
            ),
          ),
        ],
      ),
    );
  }
}

// Present actual stored image-feature measurements as readable UI instead
// of showing the raw PostgreSQL JSONB map on the History screen.
class _SavedMeasurementsPanel extends StatelessWidget {
  final Map<String, dynamic> features;

  const _SavedMeasurementsPanel({required this.features});

  Map<String, dynamic>? _section(String key) {
    final raw = features[key];
    return raw is Map ? Map<String, dynamic>.from(raw) : null;
  }

  static String _number(num number) => number.toStringAsFixed(2);

  @override
  Widget build(BuildContext context) {
    final color = _section('color');
    final photo = _section('image_quality');
    final texture = _section('texture');

    final colorShares = <MapEntry<String, double>>[];
    final analyzedPixels = color?['analyzed_pixel_percentage'];
    final distribution = color?['color_distribution'];
    if (distribution is Map) {
      for (final entry in distribution.entries) {
        if (entry.value is num) {
          colorShares.add(
            MapEntry(entry.key.toString(), (entry.value as num).toDouble()),
          );
        }
      }
      colorShares.sort((a, b) => b.value.compareTo(a.value));
    }

    final photoMetrics = <Widget>[];
    final width = photo?['width'];
    final height = photo?['height'];
    if (width is num && height is num) {
      photoMetrics.add(
        _MeasurementMetric(
          label: 'Resolution',
          value: '$width × $height px',
        ),
      );
    }
    if (photo?['brightness'] is num) {
      photoMetrics.add(
        _MeasurementMetric(
          label: 'Brightness (0–255)',
          value: _number(photo!['brightness'] as num),
        ),
      );
    }
    if (photo?['contrast'] is num) {
      photoMetrics.add(
        _MeasurementMetric(
          label: 'Contrast',
          value: _number(photo!['contrast'] as num),
        ),
      );
    }
    if (photo?['sharpness_score'] is num) {
      photoMetrics.add(
        _MeasurementMetric(
          label: 'Sharpness score',
          value: _number(photo!['sharpness_score'] as num),
        ),
      );
    }

    final issues = <String>[];
    final rawIssues = photo?['issues'];
    if (rawIssues is List) {
      for (final issue in rawIssues) {
        if (issue is String && issue.trim().isNotEmpty) {
          issues.add(issue);
        }
      }
    }

    final textureScope = texture?['analysis_scope'];
    final edgePercentage = texture?['edge_density_percentage'];
    final textureMetrics = <Widget>[];
    if (texture?['texture_level'] is String) {
      textureMetrics.add(
        _MeasurementMetric(
          label: 'Texture level',
          value: texture!['texture_level'] as String,
        ),
      );
    }
    if (texture?['texture_variation'] is num) {
      textureMetrics.add(
        _MeasurementMetric(
          label: 'Texture variation',
          value: _number(texture!['texture_variation'] as num),
        ),
      );
    }
    if (edgePercentage is num) {
      textureMetrics.add(
        _MeasurementMetric(
          label: 'Visible edge pixels',
          value: '${_number(edgePercentage)}%',
        ),
      );
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surfaceDark,
        borderRadius: BorderRadius.circular(AppRadius.medium),
        border: Border.all(color: AppColors.disabled),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.tune_outlined, color: AppColors.primary, size: 22),
              SizedBox(width: 10),
              Expanded(
                child: Text(
                  'Image Measurements',
                  style: TextStyle(
                    color: AppColors.textPrimary,
                    fontWeight: FontWeight.bold,
                    fontSize: 17,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          if (color != null)
            _MeasurementSection(
              icon: Icons.palette_outlined,
              title: 'Color Distribution',
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (colorShares.isEmpty)
                    const Text(
                      'No color distribution was determined.',
                      style: TextStyle(color: AppColors.textSecondary),
                    )
                  else ...[
                    for (final share in colorShares) ...[
                      _ColorShareBar(
                        label: share.key,
                        percentage: share.value,
                      ),
                      const SizedBox(height: 12),
                    ],
                  ],
                  if (analyzedPixels is num) ...[
                    const SizedBox(height: 4),
                    Text(
                      '${_number(analyzedPixels)}% '
                      'of image pixels were included in color analysis.',
                      style: const TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 12,
                        height: 1.4,
                      ),
                    ),
                  ],
                  const SizedBox(height: 6),
                  const Text(
                    'Color shares are based on sufficiently colored pixels, '
                    'not seaweed-only pixels.',
                    style: TextStyle(
                      color: AppColors.textMuted,
                      fontSize: 12,
                      height: 1.4,
                    ),
                  ),
                ],
              ),
            ),

          if (photo != null)
            _MeasurementSection(
              icon: Icons.photo_camera_outlined,
              title: 'Photographic Quality',
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (photoMetrics.isNotEmpty)
                    Wrap(spacing: 10, runSpacing: 10, children: photoMetrics),
                  if (issues.isNotEmpty) ...[
                    const SizedBox(height: 14),
                    const Text(
                      'Photo checks to review',
                      style: TextStyle(
                        color: AppColors.textPrimary,
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 8),
                    for (final issue in issues)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 6),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Icon(
                              Icons.info_outline,
                              color: AppColors.primary,
                              size: 16,
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                issue,
                                style: const TextStyle(
                                  color: AppColors.textSecondary,
                                  fontSize: 13,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                  ] else if (photo['summary'] is String) ...[
                    const SizedBox(height: 10),
                    Text(
                      photo['summary'] as String,
                      style: const TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ],
              ),
            ),

          if (texture != null)
            _MeasurementSection(
              icon: Icons.grain_outlined,
              title: 'Texture & Edge Detail',
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (textureMetrics.isNotEmpty)
                    Wrap(spacing: 10, runSpacing: 10, children: textureMetrics),
                  if (textureScope is String) ...[
                    const SizedBox(height: 10),
                    Text(
                      'Analysis scope: $textureScope',
                      style: const TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ],
              ),
            ),

          const Padding(
            padding: EdgeInsets.only(top: 4),
            child: Text(
              'These image-wide measurements are affected by lighting and '
              'background. They are not a biological freshness test; '
              'the quality grade comes from the separate quality model.',
              style: TextStyle(
                color: AppColors.textMuted,
                fontSize: 12,
                height: 1.5,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _MeasurementSection extends StatelessWidget {
  final IconData icon;
  final String title;
  final Widget child;

  const _MeasurementSection({
    required this.icon,
    required this.title,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: AppColors.primary, size: 18),
              const SizedBox(width: 9),
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(
                    color: AppColors.textPrimary,
                    fontWeight: FontWeight.w600,
                    fontSize: 15,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          child,
        ],
      ),
    );
  }
}

class _ColorShareBar extends StatelessWidget {
  final String label;
  final double percentage;

  const _ColorShareBar({
    required this.label,
    required this.percentage,
  });

  static Color _swatch(String colorName) {
    switch (colorName.toLowerCase()) {
      case 'blue':
        return const Color(0xFF599BD5);
      case 'green':
        return const Color(0xFF69B85C);
      case 'yellow':
        return const Color(0xFFD6B84D);
      case 'brown':
        return const Color(0xFF987453);
      case 'red':
        return const Color(0xFFE76C66);
      case 'orange':
        return const Color(0xFFDD9748);
      case 'purple':
        return const Color(0xFFA68ADB);
      case 'pink':
        return const Color(0xFFE18FAE);
      default:
        return AppColors.primary;
    }
  }

  @override
  Widget build(BuildContext context) {
    final color = _swatch(label);
    final progress = percentage.clamp(0.0, 100.0).toDouble() / 100.0;

    return Row(
      children: [
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(3),
          ),
        ),
        const SizedBox(width: 8),
        SizedBox(
          width: 58,
          child: Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: AppColors.textSecondary,
              fontSize: 12,
            ),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: LinearProgressIndicator(
              value: progress,
              minHeight: 9,
              backgroundColor: AppColors.surface,
              valueColor: AlwaysStoppedAnimation<Color>(color),
            ),
          ),
        ),
        const SizedBox(width: 8),
        SizedBox(
          width: 55,
          child: Text(
            '${percentage.toStringAsFixed(2)}%',
            textAlign: TextAlign.right,
            style: const TextStyle(
              color: AppColors.textPrimary,
              fontWeight: FontWeight.w600,
              fontSize: 12,
            ),
          ),
        ),
      ],
    );
  }
}

class _MeasurementMetric extends StatelessWidget {
  final String label;
  final String value;

  const _MeasurementMetric({
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 154,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppRadius.small),
        border: Border.all(color: AppColors.disabled),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(
              color: AppColors.textMuted,
              fontSize: 11,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            value,
            style: const TextStyle(
              color: AppColors.textPrimary,
              fontWeight: FontWeight.w600,
              fontSize: 15,
            ),
          ),
        ],
      ),
    );
  }
}

// Fetch a saved record's original image from the authenticated API.
// The list endpoint returns summary JSON, not image bytes.
class _SavedImagePreview extends StatefulWidget {
  final int classificationId;

  const _SavedImagePreview({required this.classificationId});

  @override
  State<_SavedImagePreview> createState() => _SavedImagePreviewState();
}

class _SavedImagePreviewState extends State<_SavedImagePreview> {
  final HistoryService _historyService = const HistoryService();
  late Future<Uint8List> _imageRequest;

  @override
  void initState() {
    super.initState();
    _imageRequest = _historyService.fetchSavedImage(widget.classificationId);
  }

  @override
  void didUpdateWidget(covariant _SavedImagePreview oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.classificationId != widget.classificationId) {
      _imageRequest = _historyService.fetchSavedImage(widget.classificationId);
    }
  }

  void _retry() {
    setState(() {
      _imageRequest = _historyService.fetchSavedImage(widget.classificationId);
    });
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final imageHeight = constraints.maxWidth < 600 ? 300.0 : 420.0;

        return Container(
          width: double.infinity,
          height: imageHeight,
          decoration: BoxDecoration(
            color: AppColors.surfaceDark,
            borderRadius: BorderRadius.circular(AppRadius.large),
            border: Border.all(color: AppColors.borderLight, width: 2),
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(AppRadius.large - 2),
            child: FutureBuilder<Uint8List>(
              future: _imageRequest,
              builder: (context, snapshot) {
                if (snapshot.connectionState != ConnectionState.done) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (snapshot.hasError) {
                  return Center(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(
                            Icons.broken_image_outlined,
                            color: AppColors.textMuted,
                            size: 38,
                          ),
                          const SizedBox(height: 12),
                          const Text(
                            'Unable to load the saved image.',
                            style: TextStyle(color: AppColors.textPrimary),
                          ),
                          const SizedBox(height: 12),
                          TextButton.icon(
                            onPressed: _retry,
                            icon: const Icon(Icons.refresh_rounded),
                            label: const Text('Retry'),
                          ),
                        ],
                      ),
                    ),
                  );
                }

                final imageBytes = snapshot.data;
                if (imageBytes == null || imageBytes.isEmpty) {
                  return const Center(
                    child: Text(
                      'No image is available for this record.',
                      style: TextStyle(color: AppColors.textSecondary),
                    ),
                  );
                }

                return Image.memory(
                  imageBytes,
                  fit: BoxFit.contain,
                  filterQuality: FilterQuality.high,
                  errorBuilder: (context, error, stackTrace) {
                    return const Center(
                      child: Text(
                        'Unable to display the saved image.',
                        style: TextStyle(color: AppColors.textSecondary),
                      ),
                    );
                  },
                );
              },
            ),
          ),
        );
      },
    );
  }
}

class _SummaryField extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;

  const _SummaryField({
    required this.label,
    required this.value,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: AppColors.primary, size: 21),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: const TextStyle(
                    color: AppColors.textMuted,
                    fontSize: 12,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  value,
                  style: const TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _HistoryDetails extends StatelessWidget {
  final ClassificationRecord record;
  final bool useInternalScroll;

  const _HistoryDetails({required this.record, this.useInternalScroll = true});

  @override
  Widget build(BuildContext context) {
    final content = Padding(
      padding: const EdgeInsets.all(28),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _RecordHeader(record: record),

          const SizedBox(height: 24),

          const _HistoryImageHeading(),
          const SizedBox(height: 12),
          _ImagePreview(record: record),

          const SizedBox(height: 24),

          ClassificationSummary(result: record.result),

          const SizedBox(height: 24),

          CharacteristicsPanel(result: record.result),
        ],
      ),
    );

    if (useInternalScroll) {
      return SingleChildScrollView(child: content);
    }

    return content;
  }
}

class _RecordHeader extends StatelessWidget {
  final ClassificationRecord record;

  const _RecordHeader({required this.record});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppRadius.large),
        border: Border.all(color: AppColors.borderPrimary, width: 1.5),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: AppColors.primaryDark,
              borderRadius: BorderRadius.circular(AppRadius.medium),
            ),
            child: const Icon(
              Icons.history,
              color: AppColors.primary,
              size: 26,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Saved Classification Record',
                  style: TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  '${record.displayDate} · ${record.displayTitle}',
                  style: const TextStyle(color: AppColors.textSecondary),
                ),
                const SizedBox(height: 4),
                Text(
                  record.fileName,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(color: AppColors.textMuted),
                ),
                const SizedBox(height: 12),
                const _ReportStatusChip(
                  label: 'Current session',
                  detailed: true,
                ),
              ],
            ),
          ),
          // Server-side DELETE is not yet implemented. Do not allow an
          // in-memory-only deletion that falsely claims to erase PostgreSQL.
          const Tooltip(
            message: 'Delete will be available after backend support is added',
            child: Icon(Icons.delete_outline, color: AppColors.textMuted),
          ),
        ],
      ),
    );
  }
}

class _ImagePreview extends StatelessWidget {
  final ClassificationRecord record;

  const _ImagePreview({required this.record});

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final imageHeight = constraints.maxWidth < 600 ? 300.0 : 420.0;

        return Container(
          width: double.infinity,
          height: imageHeight,
          decoration: BoxDecoration(
            color: AppColors.surfaceDark,
            borderRadius: BorderRadius.circular(AppRadius.large),
            border: Border.all(color: AppColors.borderLight, width: 2),
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(AppRadius.large - 2),
            child: Image.memory(
              record.imageBytes,
              fit: BoxFit.contain,
              filterQuality: FilterQuality.high,
            ),
          ),
        );
      },
    );
  }
}

class _EmptyHistoryView extends StatelessWidget {
  const _EmptyHistoryView();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Container(
          constraints: const BoxConstraints(maxWidth: 520),
          padding: const EdgeInsets.all(32),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(AppRadius.large),
            border: Border.all(color: AppColors.disabled),
          ),
          child: const Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.history_outlined,
                size: 64,
                color: AppColors.textMuted,
              ),

              SizedBox(height: 20),

              Text(
                'No Saved Records',
                style: TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                ),
              ),

              SizedBox(height: 10),

              Text(
                'Saved classification results will appear here. '
                'Classify a Guso image and press Save to create a record.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 14,
                  height: 1.5,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
