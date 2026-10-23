import 'package:flutter/material.dart';

import '../../app/theme.dart';
import '../../models/seaweed_info.dart';

class SeaweedDetailScreen extends StatelessWidget {
  final SeaweedInfo seaweed;
  final String language;

  const SeaweedDetailScreen({
    super.key,
    required this.seaweed,
    required this.language,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.surfaceDark,
        foregroundColor: AppColors.textPrimary,
        elevation: 0,
        title: const Text(
          'Seaweed Details',
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

              _buildTitleSection(context),
              const SizedBox(height: AppSpacing.lg),

              _buildInformationCard(context),
              const SizedBox(height: AppSpacing.lg),

              _buildDescriptionCard(context),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildImage() {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(
          AppRadius.large,
        ),
        border: Border.all(
          color: AppColors.borderLight,
        ),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(
          AppRadius.large,
        ),
        child: AspectRatio(
          aspectRatio: 4 / 3,
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
                        size: 52,
                      ),
                      SizedBox(
                        height: AppSpacing.sm,
                      ),
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
      ),
    );
  }

  Widget _buildTitleSection(BuildContext context) {
    final localizedName = seaweed.getName(language);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          localizedName,
          style: Theme.of(context)
              .textTheme
              .headlineSmall
              ?.copyWith(
                color: AppColors.textPrimary,
                fontWeight: FontWeight.w700,
              ),
        ),

        const SizedBox(height: 6),

        Text(
          seaweed.scientificName,
          style: Theme.of(context)
              .textTheme
              .titleMedium
              ?.copyWith(
                color: AppColors.primary,
                fontStyle: FontStyle.italic,
                fontWeight: FontWeight.w600,
              ),
        ),

        const SizedBox(height: AppSpacing.sm),

        Container(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.sm,
            vertical: 6,
          ),
          decoration: BoxDecoration(
            color: AppColors.primaryDark,
            borderRadius: BorderRadius.circular(
              AppRadius.large,
            ),
            border: Border.all(
              color: AppColors.primary,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.language_outlined,
                color: AppColors.primary,
                size: 15,
              ),
              const SizedBox(width: 5),
              Text(
                language,
                style: const TextStyle(
                  color: AppColors.primary,
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildDescriptionCard(BuildContext context) {
    final description = seaweed.getDescription(language);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.lg),
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
          Row(
            children: [
              const Icon(
                Icons.menu_book_outlined,
                color: AppColors.primary,
                size: 22,
              ),
              const SizedBox(width: AppSpacing.sm),
              Text(
                'About',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      color: AppColors.textPrimary,
                      fontWeight: FontWeight.w700,
                    ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          Text(
            description.trim().isEmpty
                ? 'No description available.'
                : description,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: AppColors.textSecondary,
                  height: 1.6,
                ),
          ),
        ],
      ),
    );
  }

  Widget _buildInformationCard(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: AppColors.surfaceDark,
        borderRadius: BorderRadius.circular(
          AppRadius.large,
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
                Icons.info_outline,
                color: AppColors.primary,
                size: 22,
              ),
              const SizedBox(width: AppSpacing.sm),
              Text(
                'Seaweed Information',
                style: Theme.of(context)
                    .textTheme
                    .titleMedium
                    ?.copyWith(
                      color: AppColors.textPrimary,
                      fontWeight: FontWeight.w700,
                    ),
              ),
            ],
          ),

          const SizedBox(height: AppSpacing.lg),

          _buildInfoRow(
            context,
            label: 'Common Name',
            value: seaweed.englishName,
          ),

          const SizedBox(height: AppSpacing.md),

          _buildInfoRow(
            context,
            label: 'Local Name',
            value: seaweed.bisayaName,
          ),

          const SizedBox(height: AppSpacing.md),

          _buildInfoRow(
            context,
            label: 'Scientific Name',
            value: seaweed.scientificName,
            italic: true,
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(
    BuildContext context, {
    required String label,
    required String value,
    bool italic = false,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: Theme.of(context)
              .textTheme
              .bodySmall
              ?.copyWith(
                color: AppColors.textMuted,
              ),
        ),
        const SizedBox(height: 4),
        Text(
          value.trim().isEmpty
              ? 'Not available'
              : value,
          style: Theme.of(context)
              .textTheme
              .bodyMedium
              ?.copyWith(
                color: AppColors.textPrimary,
                fontWeight: FontWeight.w600,
                fontStyle: italic
                    ? FontStyle.italic
                    : FontStyle.normal,
              ),
        ),
      ],
    );
  }
}