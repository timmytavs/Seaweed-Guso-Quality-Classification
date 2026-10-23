import 'dart:io';

import 'package:flutter/material.dart';

import '../../app/theme.dart';
import '../../models/classification_record.dart';

import 'package:provider/provider.dart';

import '../../providers/settings_provider.dart';

import '../../data/seaweed_data.dart';
import '../../models/seaweed_info.dart';

class HistoryDetailScreen extends StatelessWidget {
  final ClassificationRecord record;

  const HistoryDetailScreen({
    super.key,
    required this.record,
  });

  @override
  Widget build(BuildContext context) {
    final settingsProvider = context.watch<SettingsProvider>();

    final SeaweedInfo? seaweed =
      SeaweedData.findByClassificationLabel(record.species);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.surfaceDark,
        foregroundColor: AppColors.textPrimary,
        elevation: 0,
        title: const Text(
          'Classification Details',
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildImage(),
              const SizedBox(height: AppSpacing.lg),
              _buildResultCard(
                context,
                seaweed: seaweed,
                showConfidence: settingsProvider.showConfidence,
                showImageQuality: settingsProvider.showImageQuality,
              ),
              const SizedBox(height: AppSpacing.lg),
              _buildSavedInfoCard(context),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildImage() {
    return ClipRRect(
      borderRadius: BorderRadius.circular(AppRadius.large),
      child: AspectRatio(
        aspectRatio: 1,
        child: Image.file(
          File(record.imagePath),
          width: double.infinity,
          fit: BoxFit.cover,
          errorBuilder: (
            context,
            error,
            stackTrace,
          ) {
            return Container(
              color: AppColors.surfaceDark,
              child: const Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.broken_image_outlined,
                      color: AppColors.textMuted,
                      size: 52,
                    ),
                    SizedBox(height: AppSpacing.sm),
                    Text(
                      'Image unavailable',
                      style: TextStyle(
                        color: AppColors.textMuted,
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildResultCard(
    BuildContext context, {
    required SeaweedInfo? seaweed,
    required bool showConfidence,
    required bool showImageQuality,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppRadius.large),
        border: Border.all(
          color: AppColors.primary,
          width: 1.2,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.eco_outlined,
                color: AppColors.primary,
                size: 24,
              ),
              const SizedBox(width: AppSpacing.sm),
              Text(
                'Classification Result',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      color: AppColors.textPrimary,
                      fontWeight: FontWeight.w700,
                    ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.lg),

          Text(
            'Species',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: AppColors.textMuted,
                ),
          ),
          const SizedBox(height: 4),
          Text(
            record.species,
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  color: AppColors.primary,
                  fontWeight: FontWeight.w700,
                ),
          ),

          if (seaweed != null) ...[
            const SizedBox(height: AppSpacing.md),

            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(AppSpacing.md),
              decoration: BoxDecoration(
                color: AppColors.surfaceDark,
                borderRadius: BorderRadius.circular(
                  AppRadius.medium,
                ),
                border: Border.all(
                  color: AppColors.borderLight,
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Seaweed Information',
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                          color: AppColors.textPrimary,
                          fontWeight: FontWeight.w700,
                        ),
                  ),

                  const SizedBox(height: AppSpacing.md),

                  Text(
                    'Scientific Name',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: AppColors.textMuted,
                        ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    seaweed.scientificName,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: AppColors.textPrimary,
                          fontStyle: FontStyle.italic,
                          fontWeight: FontWeight.w600,
                        ),
                  ),

                  const SizedBox(height: AppSpacing.md),

                  Text(
                    'Common Name',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: AppColors.textMuted,
                        ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    seaweed.englishName,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: AppColors.textPrimary,
                          fontWeight: FontWeight.w600,
                        ),
                  ),

                  const SizedBox(height: AppSpacing.md),

                  Text(
                    'Local Name',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: AppColors.textMuted,
                        ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    seaweed.bisayaName,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: AppColors.textPrimary,
                          fontWeight: FontWeight.w600,
                        ),
                  ),

                  const SizedBox(height: AppSpacing.md),

                  Text(
                    'Description',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: AppColors.textMuted,
                        ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    seaweed.englishDescription,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: AppColors.textSecondary,
                          height: 1.5,
                        ),
                  ),
                ],
              ),
            ),
          ],

          const SizedBox(height: AppSpacing.md),

          if (record.result.hasQualityGrade ||
              record.result.hasFreshness) ...[
            if (record.result.hasQualityGrade)
              _buildResultMetricCard(
                context,
                icon: Icons.workspace_premium_outlined,
                label: 'Quality Grade',
                value: record.result.qualityGrade!,
              ),

            if (record.result.hasQualityGrade &&
                record.result.hasFreshness)
              const SizedBox(height: AppSpacing.sm),

            if (record.result.hasFreshness)
              _buildResultMetricCard(
                context,
                icon: Icons.eco_outlined,
                label: 'Freshness',
                value: record.result.freshness!,
              ),

            const SizedBox(height: AppSpacing.sm),
          ],

          if (showConfidence ||
              (showImageQuality &&
                  record.result.hasImageQuality)) ...[
            if (showConfidence)
              _buildResultMetricCard(
                context,
                icon: Icons.analytics_outlined,
                label: 'Confidence',
                value: record.formattedConfidence,
              ),

            if (showConfidence &&
                showImageQuality &&
                record.result.hasImageQuality)
              const SizedBox(height: AppSpacing.sm),

            if (showImageQuality &&
                record.result.hasImageQuality)
              _buildResultMetricCard(
                context,
                icon: Icons.image_outlined,
                label: 'Image Quality',
                value: record.result.imageQuality!,
              ),

            const SizedBox(height: AppSpacing.md),
          ],

          if (record.result.hasSummary) ...[
            const SizedBox(height: AppSpacing.md),

            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(AppSpacing.md),
              decoration: BoxDecoration(
                color: AppColors.surfaceDark,
                borderRadius: BorderRadius.circular(
                  AppRadius.medium,
                ),
                border: Border.all(
                  color: AppColors.borderLight,
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(
                        Icons.description_outlined,
                        color: AppColors.primary,
                        size: 21,
                      ),
                      const SizedBox(width: AppSpacing.sm),
                      Text(
                        'Summary',
                        style: Theme.of(context).textTheme.titleSmall?.copyWith(
                              color: AppColors.textPrimary,
                              fontWeight: FontWeight.w700,
                            ),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.md),
                  Text(
                    record.result.summary!,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: AppColors.textSecondary,
                          height: 1.5,
                        ),
                  ),
                ],
              ),
            ),
          ],

          if (record.result.hasObservedCharacteristics) ...[
            const SizedBox(height: AppSpacing.md),

            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(AppSpacing.md),
              decoration: BoxDecoration(
                color: AppColors.surfaceDark,
                borderRadius: BorderRadius.circular(
                  AppRadius.medium,
                ),
                border: Border.all(
                  color: AppColors.borderLight,
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(
                        Icons.visibility_outlined,
                        color: AppColors.primary,
                        size: 21,
                      ),
                      const SizedBox(width: AppSpacing.sm),
                      Text(
                        'Observed Characteristics',
                        style: Theme.of(context).textTheme.titleSmall?.copyWith(
                              color: AppColors.textPrimary,
                              fontWeight: FontWeight.w700,
                            ),
                      ),
                    ],
                  ),

                  if (record.result.hasColor) ...[
                    const SizedBox(height: AppSpacing.md),
                    _buildCharacteristicRow(
                      context,
                      label: 'Color',
                      value: record.result.color!,
                    ),
                  ],

                  if (record.result.hasVisualTexture) ...[
                    const SizedBox(height: AppSpacing.md),
                    _buildCharacteristicRow(
                      context,
                      label: 'Visual Texture',
                      value: record.result.visualTexture!,
                    ),
                  ],

                  if (record.result.hasSurfaceCondition) ...[
                    const SizedBox(height: AppSpacing.md),
                    _buildCharacteristicRow(
                      context,
                      label: 'Surface Condition',
                      value: record.result.surfaceCondition!,
                    ),
                  ],

                  if (record.result.hasVisibleDefects) ...[
                    const SizedBox(height: AppSpacing.md),
                    _buildCharacteristicRow(
                      context,
                      label: 'Visible Defects',
                      value: record.result.visibleDefects!,
                    ),
                  ],
                ],
              ),
            ),
          ],

          if (record.modelName != null &&
              record.modelName!.trim().isNotEmpty) ...[
            const SizedBox(height: AppSpacing.lg),
            Text(
              'Model',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: AppColors.textMuted,
                  ),
            ),
            const SizedBox(height: 4),
            Text(
              record.modelName!,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: AppColors.textSecondary,
                  ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildResultMetricCard(
    BuildContext context, {
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Container(
      width: double.infinity,
      constraints: const BoxConstraints(
        minHeight: 118,
      ),
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.surfaceDark,
        borderRadius: BorderRadius.circular(
          AppRadius.medium,
        ),
        border: Border.all(
          color: AppColors.borderLight,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            icon,
            color: AppColors.primary,
            size: 22,
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            label,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: AppColors.textMuted,
                ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  color: AppColors.textPrimary,
                  fontWeight: FontWeight.w700,
                ),
          ),
        ],
      ),
    );
  }

  Widget _buildCharacteristicRow(
    BuildContext context, {
    required String label,
    required String value,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: AppColors.textMuted,
              ),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: AppColors.textPrimary,
                fontWeight: FontWeight.w600,
                height: 1.4,
              ),
        ),
      ],
    );
  }

  Widget _buildSavedInfoCard(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: AppColors.surfaceDark,
        borderRadius: BorderRadius.circular(AppRadius.large),
        border: Border.all(
          color: AppColors.borderLight,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.history_outlined,
                color: AppColors.primary,
                size: 22,
              ),
              const SizedBox(width: AppSpacing.sm),
              Text(
                'Saved Record',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      color: AppColors.textPrimary,
                      fontWeight: FontWeight.w700,
                    ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.lg),

          _buildInfoRow(
            context,
            label: 'Record ID',
            value: record.id.toString(),
          ),

          const SizedBox(height: AppSpacing.md),

          _buildInfoRow(
            context,
            label: 'Saved Date',
            value: _formatDate(record.createdAt),
          ),

          const SizedBox(height: AppSpacing.md),

          _buildInfoRow(
            context,
            label: 'Image Location',
            value: record.imagePath,
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(
    BuildContext context, {
    required String label,
    required String value,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: AppColors.textMuted,
              ),
        ),
        const SizedBox(height: 4),
        Text(
          value.trim().isEmpty ? 'Not available' : value,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: AppColors.textPrimary,
                fontWeight: FontWeight.w600,
              ),
        ),
      ],
    );
  }

  String _formatDate(DateTime date) {
    final month = date.month.toString().padLeft(2, '0');
    final day = date.day.toString().padLeft(2, '0');
    final hour = date.hour.toString().padLeft(2, '0');
    final minute = date.minute.toString().padLeft(2, '0');

    return '${date.year}-$month-$day  $hour:$minute';
  }
}