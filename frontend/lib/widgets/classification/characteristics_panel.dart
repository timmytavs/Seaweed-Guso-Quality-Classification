import 'package:flutter/material.dart';

import '../../app/theme.dart';
import '../../models/classification_result.dart';

class CharacteristicsPanel extends StatelessWidget {
  final ClassificationResult result;

  const CharacteristicsPanel({super.key, required this.result});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppRadius.large),
        border: Border.all(color: AppColors.borderLight, width: 1.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Observed Characteristics',
            style: TextStyle(
              color: AppColors.textPrimary,
              fontSize: 22,
              fontWeight: FontWeight.bold,
            ),
          ),

          const SizedBox(height: 8),

          const Text(
            'Color and visual texture are estimated from the whole image, '
            'including its background. Surface condition and visible defects '
            'are not separately analyzed.',
            style: TextStyle(
              color: AppColors.textSecondary,
              fontSize: 14,
              height: 1.4,
            ),
          ),

          const SizedBox(height: 24),

          _CharacteristicItem(
            icon: Icons.palette_outlined,
            title: 'Color',
            value: result.color,
          ),

          const SizedBox(height: 14),

          _CharacteristicItem(
            icon: Icons.texture_outlined,
            title: 'Visual Texture',
            value: result.visualTexture,
          ),

          const SizedBox(height: 14),

          _CharacteristicItem(
            icon: Icons.visibility_outlined,
            title: 'Surface Condition',
            value: result.surfaceCondition,
          ),

          const SizedBox(height: 14),

          _CharacteristicItem(
            icon: Icons.warning_amber_rounded,
            title: 'Visible Defects',
            value: result.visibleDefects,
          ),
        ],
      ),
    );
  }
}

class _CharacteristicItem extends StatelessWidget {
  final IconData icon;
  final String title;
  final String value;

  const _CharacteristicItem({
    required this.icon,
    required this.title,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.surfaceDark,
        borderRadius: BorderRadius.circular(AppRadius.medium),
        border: Border.all(color: AppColors.disabled),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
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

          const SizedBox(width: 16),

          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    color: AppColors.textMuted,
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                  ),
                ),

                const SizedBox(height: 5),

                Text(
                  value,
                  style: const TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 15,
                    fontWeight: FontWeight.w500,
                    height: 1.4,
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
