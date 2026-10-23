import 'dart:io';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../app/theme.dart';
import '../../models/classification_record.dart';
import '../../providers/classification_provider.dart';
import '../../providers/settings_provider.dart';
import '../../widgets/common/empty_state.dart';
import 'history_detail_screen.dart';

class HistoryScreen extends StatelessWidget {
  const HistoryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final classificationProvider =
        context.watch<ClassificationProvider>();
    final settingsProvider =
        context.watch<SettingsProvider>();

    final records = classificationProvider.records;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.lg,
                AppSpacing.lg,
                AppSpacing.lg,
                AppSpacing.md,
              ),
              child: _buildHeader(
                context,
                recordCount: records.length,
                hasRecords: records.isNotEmpty,
              ),
            ),

            Expanded(
              child: records.isEmpty
                  ? _buildEmptyHistory(context)
                  : ListView.separated(
                      padding: const EdgeInsets.fromLTRB(
                        AppSpacing.lg,
                        AppSpacing.sm,
                        AppSpacing.lg,
                        AppSpacing.xl,
                      ),
                      itemCount: records.length,
                      separatorBuilder: (_, _) =>
                          const SizedBox(
                            height: AppSpacing.md,
                          ),
                      itemBuilder: (context, index) {
                        final record = records[index];

                        return _buildHistoryCard(
                          context,
                          record,
                          showConfidence:
                              settingsProvider.showConfidence,
                          showImageQuality:
                              settingsProvider.showImageQuality,
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(
    BuildContext context, {
    required int recordCount,
    required bool hasRecords,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 46,
          height: 46,
          decoration: BoxDecoration(
            color: AppColors.primaryDark,
            borderRadius: BorderRadius.circular(
              AppRadius.medium,
            ),
            border: Border.all(
              color: AppColors.primary,
            ),
          ),
          child: const Icon(
            Icons.history_outlined,
            color: AppColors.primary,
            size: 25,
          ),
        ),

        const SizedBox(width: AppSpacing.md),

        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'History',
                style: Theme.of(context)
                    .textTheme
                    .titleLarge
                    ?.copyWith(
                      color: AppColors.textPrimary,
                      fontWeight: FontWeight.w700,
                    ),
              ),

              const SizedBox(height: 4),

              Text(
                recordCount == 0
                    ? 'Your saved classifications will appear here.'
                    : '$recordCount saved classification${recordCount == 1 ? '' : 's'}',
                style: Theme.of(context)
                    .textTheme
                    .bodyMedium
                    ?.copyWith(
                      color: AppColors.textSecondary,
                      height: 1.4,
                    ),
              ),
            ],
          ),
        ),

        if (hasRecords)
          PopupMenuButton<String>(
            color: AppColors.surface,
            tooltip: 'History options',
            icon: const Icon(
              Icons.more_vert,
              color: AppColors.textSecondary,
            ),
            onSelected: (value) {
              if (value == 'clear') {
                _showClearHistoryDialog(context);
              }
            },
            itemBuilder: (context) => [
              const PopupMenuItem<String>(
                value: 'clear',
                child: Row(
                  children: [
                    Icon(
                      Icons.delete_sweep_outlined,
                      color: AppColors.error,
                      size: 20,
                    ),
                    SizedBox(width: AppSpacing.sm),
                    Text(
                      'Clear History',
                      style: TextStyle(
                        color: AppColors.error,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
      ],
    );
  }

  Widget _buildHistoryCard(
    BuildContext context,
    ClassificationRecord record, {
    required bool showConfidence,
    required bool showImageQuality,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(
          AppRadius.large,
        ),
        onTap: () {
          context
              .read<ClassificationProvider>()
              .selectRecord(record);

          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (_) => HistoryDetailScreen(          // --------- This Line
                record: record,
              ),
            ),
          );
        },
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.all(AppSpacing.md),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(
              AppRadius.large,
            ),
            border: Border.all(
              color: AppColors.borderLight,
            ),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildThumbnail(record),

              const SizedBox(width: AppSpacing.md),

              Expanded(
                child: Column(
                  crossAxisAlignment:
                      CrossAxisAlignment.start,
                  children: [
                    Row(
                      crossAxisAlignment:
                          CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Text(
                            record.species,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: Theme.of(context)
                                .textTheme
                                .titleSmall
                                ?.copyWith(
                                  color:
                                      AppColors.textPrimary,
                                  fontWeight:
                                      FontWeight.w700,
                                ),
                          ),
                        ),

                        const SizedBox(
                          width: AppSpacing.sm,
                        ),

                        const Icon(
                          Icons.chevron_right,
                          color:
                              AppColors.textSecondary,
                          size: 22,
                        ),
                      ],
                    ),

                    const SizedBox(
                      height: AppSpacing.sm,
                    ),

                    _buildSavedDate(
                      context,
                      record.createdAt,
                    ),

                    if (showConfidence) ...[
                      const SizedBox(
                        height: AppSpacing.sm,
                      ),
                      _buildInfoChip(
                        context,
                        icon:
                            Icons.analytics_outlined,
                        label:
                            record.formattedConfidence,
                      ),
                    ],

                    if (showImageQuality &&
                        record.result
                            .hasImageQuality) ...[
                      const SizedBox(
                        height: AppSpacing.sm,
                      ),
                      _buildInfoChip(
                        context,
                        icon: Icons.image_outlined,
                        label:
                            record.result.imageQuality!,
                      ),
                    ],

                    if (record.result.hasQualityGrade ||
                        record.result.hasFreshness) ...[
                      const SizedBox(
                        height: AppSpacing.sm,
                      ),
                      Wrap(
                        spacing: AppSpacing.sm,
                        runSpacing: AppSpacing.sm,
                        children: [
                          if (record.result
                              .hasQualityGrade)
                            _buildInfoChip(
                              context,
                              icon: Icons
                                  .workspace_premium_outlined,
                              label: record.result
                                  .qualityGrade!,
                            ),

                          if (record.result
                              .hasFreshness)
                            _buildInfoChip(
                              context,
                              icon:
                                  Icons.eco_outlined,
                              label: record
                                  .result.freshness!,
                            ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildThumbnail(
    ClassificationRecord record,
  ) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(
        AppRadius.medium,
      ),
      child: SizedBox(
        width: 88,
        height: 88,
        child: Image.file(
          File(record.imagePath),
          fit: BoxFit.cover,
          errorBuilder: (
            context,
            error,
            stackTrace,
          ) {
            return Container(
              color: AppColors.surfaceDark,
              child: const Center(
                child: Icon(
                  Icons.broken_image_outlined,
                  color: AppColors.textMuted,
                  size: 28,
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildSavedDate(
    BuildContext context,
    DateTime date,
  ) {
    return Row(
      children: [
        const Icon(
          Icons.schedule_outlined,
          color: AppColors.textMuted,
          size: 15,
        ),
        const SizedBox(width: 5),
        Expanded(
          child: Text(
            _formatDate(date),
            style: Theme.of(context)
                .textTheme
                .bodySmall
                ?.copyWith(
                  color: AppColors.textMuted,
                ),
          ),
        ),
      ],
    );
  }

  Widget _buildInfoChip(
    BuildContext context, {
    required IconData icon,
    required String label,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.sm,
        vertical: 6,
      ),
      decoration: BoxDecoration(
        color: AppColors.surfaceDark,
        borderRadius: BorderRadius.circular(
          AppRadius.large,
        ),
        border: Border.all(
          color: AppColors.borderLight,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            size: 14,
            color: AppColors.primary,
          ),
          const SizedBox(width: 5),
          Flexible(
            child: Text(
              label,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(context)
                  .textTheme
                  .bodySmall
                  ?.copyWith(
                    color: AppColors.textSecondary,
                    fontWeight: FontWeight.w500,
                  ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyHistory(
    BuildContext context,
  ) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(
          AppSpacing.lg,
        ),
        child: EmptyState(
          icon: Icons.history_outlined,
          title: 'No saved classifications',
          message:
              'Classify a seaweed image and save the result to view it here.',
        ),
      ),
    );
  }

  Future<void> _showClearHistoryDialog(
    BuildContext context,
  ) async {
    final shouldClear =
        await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          backgroundColor: AppColors.surface,
          title: const Text(
            'Clear history?',
            style: TextStyle(
              color: AppColors.textPrimary,
            ),
          ),
          content: const Text(
            'All saved classification records will be removed from the current history.',
            style: TextStyle(
              color: AppColors.textSecondary,
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(
                  dialogContext,
                ).pop(false);
              },
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(
                  dialogContext,
                ).pop(true);
              },
              child: const Text(
                'Clear',
                style: TextStyle(
                  color: AppColors.error,
                ),
              ),
            ),
          ],
        );
      },
    );

    if (shouldClear != true ||
        !context.mounted) {
      return;
    }

    context
        .read<ClassificationProvider>()
        .clearHistory();

    ScaffoldMessenger.of(context)
        .showSnackBar(
      const SnackBar(
        content: Text(
          'Classification history cleared.',
        ),
      ),
    );
  }

  String _formatDate(DateTime date) {
    final hour = date.hour == 0
        ? 12
        : date.hour > 12
            ? date.hour - 12
            : date.hour;

    final minute =
        date.minute.toString().padLeft(2, '0');

    final period =
        date.hour >= 12 ? 'PM' : 'AM';

    return '${_monthName(date.month)} '
        '${date.day}, ${date.year} • '
        '$hour:$minute $period';
  }

  String _monthName(int month) {
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

    return months[month - 1];
  }
}