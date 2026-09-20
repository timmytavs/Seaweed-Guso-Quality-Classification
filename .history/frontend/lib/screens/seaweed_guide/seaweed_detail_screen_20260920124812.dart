import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../app/theme.dart';
import '../../models/seaweed_info.dart';
import '../../providers/seaweed_language_provider.dart';

class SeaweedDetailScreen extends StatelessWidget {
  final SeaweedInfo seaweed;

  const SeaweedDetailScreen({
    super.key,
    required this.seaweed,
  });

  @override
  Widget build(BuildContext context) {
    final language =
        context.watch<SeaweedLanguageProvider>().language;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(28),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildBackButton(context),

            const SizedBox(height: 20),

            _buildHeroSection(
              context,
              language,
            ),

            const SizedBox(height: 24),

            _buildLanguageSelector(context, language),

            const SizedBox(height: 24),

            _buildInfoSection(
              title: 'Description',
              icon: Icons.menu_book_outlined,
              content: seaweed.getDescription(language),
            ),

            const SizedBox(height: 18),

            _buildInfoSection(
              title: 'Identification',
              icon: Icons.visibility_outlined,
              content: seaweed.getIdentification(language),
            ),

            const SizedBox(height: 18),

            _buildInfoSection(
              title: 'Habitat',
              icon: Icons.public_outlined,
              content: seaweed.getHabitat(language),
            ),

            const SizedBox(height: 18),

            _buildInfoSection(
              title: 'Common Uses',
              icon: Icons.eco_outlined,
              content: seaweed.getUses(language),
            ),

            const SizedBox(height: 24),

            _buildLocalNameNote(),
          ],
        ),
      ),
    );
  }

  Widget _buildBackButton(BuildContext context) {
    return TextButton.icon(
      onPressed: () {
        Navigator.of(context).pop();
      },
      icon: const Icon(
        Icons.arrow_back,
      ),
      label: const Text(
        'Back to Seaweed Guide',
      ),
    );
  }

  Widget _buildHeroSection(
  BuildContext context,
  SeaweedLanguage language,
) {
  return LayoutBuilder(
    builder: (context, constraints) {
      final isCompact = constraints.maxWidth < 750;

      Widget buildImage(double height) {
        return Container(
          width: double.infinity,
          height: height,
          decoration: BoxDecoration(
            color: AppColors.surfaceDark,
            borderRadius: BorderRadius.circular(
              AppRadius.large,
            ),
            border: Border.all(
              color: AppColors.borderLight,
              width: 2,
            ),
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(
              AppRadius.large - 2,
            ),
            child: Image.asset(
              seaweed.imagePath,
              width: double.infinity,
              height: double.infinity,
              fit: BoxFit.cover,
              errorBuilder: (
                context,
                error,
                stackTrace,
              ) {
                return const Center(
                  child: Column(
                    mainAxisAlignment:
                        MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.image_not_supported_outlined,
                        size: 54,
                        color: AppColors.textMuted,
                      ),
                      SizedBox(height: 12),
                      Text(
                        'Image not available',
                        style: TextStyle(
                          color: AppColors.textMuted,
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        );
      }

      Widget buildInformation() {
        return Container(
          width: double.infinity,
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(
              AppRadius.large,
            ),
            border: Border.all(
              color: AppColors.borderPrimary,
              width: 1.5,
            ),
          ),
          child: Column(
            crossAxisAlignment:
                CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                seaweed.scientificName,
                style: const TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 30,
                  fontWeight: FontWeight.bold,
                  fontStyle: FontStyle.italic,
                ),
              ),

              const SizedBox(height: 10),

              Text(
                seaweed.getName(language),
                style: const TextStyle(
                  color: AppColors.primary,
                  fontSize: 20,
                  fontWeight: FontWeight.w600,
                ),
              ),

              const SizedBox(height: 18),

              Text(
                seaweed.getDescription(language),
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

      if (isCompact) {
        return Column(
          crossAxisAlignment:
              CrossAxisAlignment.start,
          children: [
            buildImage(280),

            const SizedBox(height: 18),

            buildInformation(),
          ],
        );
      }

      return Row(
        crossAxisAlignment:
            CrossAxisAlignment.start,
        children: [
          Expanded(
            flex: 5,
            child: buildImage(360),
          ),

          const SizedBox(width: 24),

          Expanded(
            flex: 4,
            child: buildInformation(),
          ),
        ],
      );
    },
  );
}

  Widget _buildLanguageSelector(
    BuildContext context,
    SeaweedLanguage selectedLanguage,
  ) {
    return Align(
      alignment: Alignment.centerLeft,
      child: SegmentedButton<SeaweedLanguage>(
        segments:
            SeaweedLanguage.values.map((language) {
          return ButtonSegment<SeaweedLanguage>(
            value: language,
            label: Text(
              language.label,
            ),
          );
        }).toList(),
        selected: {
          selectedLanguage,
        },
        showSelectedIcon: false,
        onSelectionChanged: (selection) {
          if (selection.isEmpty) {
            return;
          }

          context
              .read<SeaweedLanguageProvider>()
              .setLanguage(
                selection.first,
              );
        },
        style: ButtonStyle(
          backgroundColor:
              WidgetStateProperty.resolveWith(
            (states) {
              if (
                  states.contains(
                    WidgetState.selected,
                  )
              ) {
                return AppColors.primaryDark;
              }

              return AppColors.surface;
            },
          ),
          foregroundColor:
              WidgetStateProperty.resolveWith(
            (states) {
              if (
                  states.contains(
                    WidgetState.selected,
                  )
              ) {
                return AppColors.primary;
              }

              return AppColors.textSecondary;
            },
          ),
        ),
      ),
    );
  }

  Widget _buildInfoSection({
    required String title,
    required IconData icon,
    required String content,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(
          AppRadius.large,
        ),
        border: Border.all(
          color: AppColors.disabled,
        ),
      ),
      child: Row(
        crossAxisAlignment:
            CrossAxisAlignment.start,
        children: [
          Container(
            width: 46,
            height: 46,
            decoration: BoxDecoration(
              color: AppColors.primaryDark,
              borderRadius: BorderRadius.circular(
                AppRadius.medium,
              ),
            ),
            child: Icon(
              icon,
              color: AppColors.primary,
              size: 23,
            ),
          ),

          const SizedBox(width: 16),

          Expanded(
            child: Column(
              crossAxisAlignment:
                  CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),

                const SizedBox(height: 8),

                Text(
                  content,
                  style: const TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 15,
                    height: 1.6,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLocalNameNote() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surfaceDark,
        borderRadius: BorderRadius.circular(
          AppRadius.medium,
        ),
        border: Border.all(
          color: AppColors.disabled,
        ),
      ),
      child: const Row(
        crossAxisAlignment:
            CrossAxisAlignment.start,
        children: [
          Icon(
            Icons.info_outline,
            color: AppColors.primary,
            size: 20,
          ),

          SizedBox(width: 12),

          Expanded(
            child: Text(
              'Local seaweed names may vary depending on region and community usage.',
              style: TextStyle(
                color: AppColors.textSecondary,
                fontSize: 13,
                height: 1.4,
              ),
            ),
          ),
        ],
      ),
    );
  }
}