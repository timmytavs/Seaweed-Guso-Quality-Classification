import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../app/theme.dart';
import '../../models/seaweed_info.dart';
import '../../providers/seaweed_language_provider.dart';

class SeaweedCard extends StatelessWidget {
  final SeaweedInfo seaweed;
  final VoidCallback onTap;

  const SeaweedCard({
    super.key,
    required this.seaweed,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final language =
        context.watch<SeaweedLanguageProvider>().language;

    return Material(
      color: AppColors.surface,
      borderRadius: BorderRadius.circular(
        AppRadius.large,
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(
          AppRadius.large,
        ),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(
              AppRadius.large,
            ),
            border: Border.all(
              color: AppColors.disabled,
              width: 1,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Image
              AspectRatio(
                aspectRatio: 16 / 9,
                child: ClipRRect(
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(
                      AppRadius.large,
                    ),
                    topRight: Radius.circular(
                      AppRadius.large,
                    ),
                  ),
                  child: Container(
                    color: AppColors.surfaceDark,
                    child: Image.asset(
                      seaweed.imagePath,
                      width: double.infinity,
                      fit: BoxFit.cover,
                      errorBuilder: (
                        context,
                        error,
                        stackTrace,
                      ) {
                        return const Center(
                          child: Icon(
                            Icons.image_not_supported_outlined,
                            color: AppColors.textMuted,
                            size: 42,
                          ),
                        );
                      },
                    ),
                  ),
                ),
              ),

              // Card information
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.all(18),
                  child: Column(
                    crossAxisAlignment:
                        CrossAxisAlignment.start,
                    children: [
                      Text(
                        seaweed.scientificName,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: AppColors.textPrimary,
                          fontSize: 17,
                          fontWeight: FontWeight.bold,
                          fontStyle: FontStyle.italic,
                        ),
                      ),

                      const SizedBox(height: 7),

                      Text(
                        seaweed.getName(language),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: AppColors.primary,
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                        ),
                      ),

                      const SizedBox(height: 12),

                      Expanded(
                        child: Text(
                          seaweed.getDescription(language),
                          maxLines: 3,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: AppColors.textSecondary,
                            fontSize: 13,
                            height: 1.4,
                          ),
                        ),
                      ),

                      const SizedBox(height: 14),

                      Row(
                        children: [
                          const Spacer(),

                          TextButton.icon(
                            onPressed: onTap,
                            iconAlignment:
                                IconAlignment.end,
                            icon: const Icon(
                              Icons.arrow_forward,
                              size: 17,
                            ),
                            label: const Text(
                              'View More',
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}