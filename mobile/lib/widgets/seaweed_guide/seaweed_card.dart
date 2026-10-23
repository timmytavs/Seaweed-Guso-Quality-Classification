import 'package:flutter/material.dart';

import '../../app/theme.dart';
import '../../models/seaweed_info.dart';

class SeaweedCard extends StatelessWidget {
  final SeaweedInfo seaweed;
  final String language;
  final VoidCallback onTap;

  const SeaweedCard({
    super.key,
    required this.seaweed,
    required this.language,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final localizedName = seaweed.getName(language);

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppRadius.large),
        child: Container(
          width: double.infinity,
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(AppRadius.large),
            border: Border.all(
              color: AppColors.borderLight,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildImage(),
              _buildContent(
                context,
                localizedName,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildImage() {
    return ClipRRect(
      borderRadius: const BorderRadius.only(
        topLeft: Radius.circular(AppRadius.large),
        topRight: Radius.circular(AppRadius.large),
      ),
      child: AspectRatio(
        aspectRatio: 16 / 9,
        child: Image.asset(
          seaweed.imagePath,
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
                      Icons.image_not_supported_outlined,
                      color: AppColors.textMuted,
                      size: 38,
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

  Widget _buildContent(
    BuildContext context,
    String localizedName,
  ) {
    return Padding(
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  localizedName,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        color: AppColors.textPrimary,
                        fontWeight: FontWeight.w700,
                      ),
                ),
                const SizedBox(height: 4),
                Text(
                  seaweed.scientificName,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: AppColors.primary,
                        fontStyle: FontStyle.italic,
                      ),
                ),
                const SizedBox(height: AppSpacing.sm),
                Text(
                  seaweed.getDescription(language),
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: AppColors.textSecondary,
                        height: 1.45,
                      ),
                ),
              ],
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          const Padding(
            padding: EdgeInsets.only(top: 4),
            child: Icon(
              Icons.chevron_right,
              color: AppColors.textMuted,
            ),
          ),
        ],
      ),
    );
  }
}