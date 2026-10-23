import 'package:flutter/material.dart';

import '../../app/theme.dart';
import '../../models/classification_result.dart';

import 'package:provider/provider.dart';

import '../../providers/settings_provider.dart';

class ClassificationSummary extends StatelessWidget {
  final ClassificationResult result;

  const ClassificationSummary({
    super.key,
    required this.result,
  });

  @override
  Widget build(BuildContext context) {
    final settings = context.watch<SettingsProvider>();

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppRadius.large),
        border: Border.all(
          color: AppColors.borderPrimary,
          width: 1.5,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Classification Result',
            style: TextStyle(
              color: AppColors.textPrimary,
              fontSize: 22,
              fontWeight: FontWeight.bold,
            ),
          ),

          const SizedBox(height: 20),

          Wrap(
            spacing: 24,
            runSpacing: 20,
            children: [
              _ResultCard(
                title: 'Species',
                value: result.species ?? 'Not identified',
                icon: Icons.eco_outlined,
              ),

              _ResultCard(
                title: 'Quality Grade',
                value: result.qualityGrade ??
                    (result.qualityClass == 'Not available'
                        ? 'Not analyzed'
                        : result.qualityClass),
                icon: Icons.grade_outlined,
              ),

              if (settings.showConfidence)
                _ResultCard(
                  title: 'Species Confidence',
                  value: '${result.confidence.toStringAsFixed(2)}%',
                  icon: Icons.analytics_outlined,
                ),

              if (settings.showConfidence &&
                  result.qualityConfidencePercentage != null)
                _ResultCard(
                  title: 'Quality Confidence',
                  value:
                      '${result.qualityConfidencePercentage!.toStringAsFixed(2)}%',
                  icon: Icons.assessment_outlined,
                ),

              _ResultCard(
                title: 'Freshness',
                value: result.freshnessLevel,
                icon: Icons.spa_outlined,
              ),

              if (settings.showImageQuality)
                _ResultCard(
                  title: 'Image Quality',
                  value: result.imageQuality,
                  icon: Icons.image_outlined,
                ),
            ],
          ),

          const SizedBox(height: 28),

          const Divider(),

          const SizedBox(height: 20),

          const Text(
            'Seaweed Information',
            style: TextStyle(
              color: AppColors.textPrimary,
              fontSize: 18,
              fontWeight: FontWeight.w600,
            ),
          ),

          const SizedBox(height: 16),

          _InfoRow(
            label: 'Common Name',
            value: result.commonName,
          ),

          const SizedBox(height: 12),

          _InfoRow(
            label: 'Local Name',
            value: result.localName,
          ),

          if (result.scientificName != null) ...[
            const SizedBox(height: 12),
            _InfoRow(
              label: 'Scientific Name',
              value: result.scientificName!,
              italicValue: true,
            ),
          ],

          const SizedBox(height: 28),

          const Divider(),

          const SizedBox(height: 20),

          const Text(
            'Summary',
            style: TextStyle(
              color: AppColors.textPrimary,
              fontSize: 18,
              fontWeight: FontWeight.w600,
            ),
          ),

          const SizedBox(height: 12),

          Text(
            result.summary,
            style: const TextStyle(
              color: AppColors.textSecondary,
              fontSize: 15,
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }
}

class _ResultCard extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;

  const _ResultCard({
    required this.title,
    required this.value,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 220,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.surfaceDark,
        borderRadius: BorderRadius.circular(AppRadius.medium),
        border: Border.all(
          color: AppColors.disabled,
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: AppColors.primaryDark,
              borderRadius: BorderRadius.circular(
                AppRadius.small,
              ),
            ),
            child: Icon(
              icon,
              color: AppColors.primary,
              size: 22,
            ),
          ),

          const SizedBox(width: 14),

          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    color: AppColors.textMuted,
                    fontSize: 12,
                  ),
                ),

                const SizedBox(height: 4),

                Text(
                  value,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 15,
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

class _InfoRow extends StatelessWidget {
  final String label;
  final String value;
  final bool italicValue;

  const _InfoRow({
    required this.label,
    required this.value,
    this.italicValue = false,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 150,
          child: Text(
            label,
            style: const TextStyle(
              color: AppColors.textMuted,
              fontSize: 14,
            ),
          ),
        ),

        Expanded(
          child: Text(
            value,
            style: TextStyle(
              color: AppColors.textPrimary,
              fontSize: 14,
              fontWeight: FontWeight.w500,
              fontStyle:
                  italicValue ? FontStyle.italic : FontStyle.normal,
            ),
          ),
        ),
      ],
    );
  }
}