import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../app/theme.dart';
import '../../models/classification_result.dart';
import '../../providers/settings_provider.dart';

/// Shows the AI's quality result without presenting KAPPAPHYCUS as an
/// independently detected species.
class ClassificationSummary extends StatelessWidget {
  final ClassificationResult result;

  const ClassificationSummary({super.key, required this.result});

  @override
  Widget build(BuildContext context) {
    final settings = context.watch<SettingsProvider>();

    // The updated FastAPI service returns this name for its quality-only
    // predictions. The separate CLIP check does not identify the species.
    final isQualityOnly =
        result.modelName.toLowerCase() == 'mobilenet_v3_large_quality';

    final hasQualityGrade =
        result.qualityGrade != null && result.qualityGrade!.trim().isNotEmpty;
    final isRejected = result.species == null && !hasQualityGrade;

    final qualityGradeText = hasQualityGrade
        ? result.qualityGrade!
        : (result.qualityClass == 'Not available'
              ? 'Not analyzed'
              : result.qualityClass);

    // In the updated quality-only API, confidence and quality confidence
    // describe the same measurement. Display it only ONCE.
    final qualityConfidence =
        result.qualityConfidencePercentage ??
        (isQualityOnly && hasQualityGrade ? result.confidence : null);

    // Do not use the old frontend summary for quality-only results:
    // earlier model versions described a species prediction that is no
    // longer performed by the backend.
    final summaryText = isRejected
        ? (result.message.trim().isNotEmpty
              ? result.message
              : 'Image not accepted for quality classification.')
        : isQualityOnly
        ? (result.message.trim().isNotEmpty
              ? result.message
              : 'Classification successful.')
        : result.summary;

    return Container(
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
                title: isQualityOnly ? 'Target Species' : 'Species',
                value: isRejected
                    ? 'Not verified'
                    : (result.species ?? 'Not identified'),
                icon: Icons.eco_outlined,
              ),
              _ResultCard(
                title: 'Quality Grade',
                value: qualityGradeText,
                icon: Icons.grade_outlined,
              ),
              // Historic species-model reports retain their old confidence
              // field. Current quality-only reports do not claim one.
              if (settings.showConfidence && !isRejected && !isQualityOnly)
                _ResultCard(
                  title: 'Species Confidence',
                  value: '${result.confidence.toStringAsFixed(2)}%',
                  icon: Icons.analytics_outlined,
                ),
              if (settings.showConfidence &&
                  !isRejected &&
                  qualityConfidence != null)
                _ResultCard(
                  title: 'Quality Confidence',
                  value: '${qualityConfidence.toStringAsFixed(2)}%',
                  icon: Icons.assessment_outlined,
                ),
              // Freshness is not independently analyzed by the updated
              // three-class quality model. Do not repeat it as another grade.
              if (!isQualityOnly && !isRejected)
                _ResultCard(
                  title: 'Freshness',
                  value: result.freshnessLevel,
                  icon: Icons.spa_outlined,
                ),
              if (settings.showImageQuality && !isRejected)
                _ResultCard(
                  title: 'Photo Quality',
                  value: result.imageQuality,
                  icon: Icons.image_outlined,
                ),
            ],
          ),

          if (isQualityOnly && !isRejected) ...[
            const SizedBox(height: 14),
            const Text(
              'KAPPAPHYCUS is the intended input species; the AI predicts '
              'quality, not species identity.',
              style: TextStyle(
                color: AppColors.textSecondary,
                fontSize: 13,
                height: 1.4,
              ),
            ),
          ],

          // Avoid showing invented seaweed information when the eligibility
          // check rejected the photograph, or repeating the target label as
          // an AI-verified common/scientific name in quality-only mode.
          if (!isRejected && !isQualityOnly) ...[
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
            _InfoRow(label: 'Common Name', value: result.commonName),
            const SizedBox(height: 12),
            _InfoRow(label: 'Local Name', value: result.localName),
            if (result.scientificName != null) ...[
              const SizedBox(height: 12),
              _InfoRow(
                label: 'Scientific Name',
                value: result.scientificName!,
                italicValue: true,
              ),
            ],
          ],

          const SizedBox(height: 28),
          const Divider(),
          const SizedBox(height: 20),
          Text(
            isRejected ? 'Why this image was not classified' : 'Summary',
            style: const TextStyle(
              color: AppColors.textPrimary,
              fontSize: 18,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            summaryText,
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
        border: Border.all(color: AppColors.disabled),
      ),
      child: Row(
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: AppColors.primaryDark,
              borderRadius: BorderRadius.circular(AppRadius.small),
            ),
            child: Icon(icon, color: AppColors.primary, size: 22),
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
            style: const TextStyle(color: AppColors.textMuted, fontSize: 14),
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: TextStyle(
              color: AppColors.textPrimary,
              fontSize: 14,
              fontWeight: FontWeight.w500,
              fontStyle: italicValue ? FontStyle.italic : FontStyle.normal,
            ),
          ),
        ),
      ],
    );
  }
}
