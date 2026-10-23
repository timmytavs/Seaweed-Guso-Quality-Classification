import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../app/theme.dart';
import '../../providers/settings_provider.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final settingsProvider = context.watch<SettingsProvider>();

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildHeader(context),

              const SizedBox(height: AppSpacing.xl),

              _buildSectionHeader(
                context,
                icon: Icons.visibility_outlined,
                title: 'Result Display',
                description:
                    'Choose which information appears in classification results.',
              ),

              const SizedBox(height: AppSpacing.md),

              _buildSettingsCard(
                children: [
                  _buildSwitchTile(
                    context,
                    icon: Icons.analytics_outlined,
                    title: 'Show Confidence',
                    subtitle:
                        'Display the classification confidence score.',
                    value: settingsProvider.showConfidence,
                    onChanged: settingsProvider.setShowConfidence,
                  ),

                  const Divider(
                    color: AppColors.borderLight,
                    height: 1,
                  ),

                  _buildSwitchTile(
                    context,
                    icon: Icons.image_outlined,
                    title: 'Show Image Quality',
                    subtitle:
                        'Display image-quality information when available.',
                    value: settingsProvider.showImageQuality,
                    onChanged: settingsProvider.setShowImageQuality,
                  ),
                ],
              ),

              const SizedBox(height: AppSpacing.xl),

              _buildSectionHeader(
                context,
                icon: Icons.tune_outlined,
                title: 'Classification Behavior',
                description:
                    'Control how the app handles unfinished classification results.',
              ),

              const SizedBox(height: AppSpacing.md),

              _buildSettingsCard(
                children: [
                  _buildSwitchTile(
                    context,
                    icon: Icons.warning_amber_outlined,
                    title: 'Confirm Before Discard',
                    subtitle:
                        'Ask before leaving an unsaved classification result.',
                    value: settingsProvider.confirmBeforeDiscard,
                    onChanged:
                        settingsProvider.setConfirmBeforeDiscard,
                  ),
                ],
              ),

              const SizedBox(height: AppSpacing.xl),

              _buildSectionHeader(
                context,
                icon: Icons.storage_outlined,
                title: 'Data & Storage',
                description:
                    'Information about classifications saved on this device.',
              ),

              const SizedBox(height: AppSpacing.md),

              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(AppSpacing.lg),
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
                    Container(
                      width: 42,
                      height: 42,
                      decoration: BoxDecoration(
                        color: AppColors.primaryDark,
                        borderRadius: BorderRadius.circular(
                          AppRadius.medium,
                        ),
                      ),
                      child: const Icon(
                        Icons.info_outline,
                        color: AppColors.primary,
                        size: 22,
                      ),
                    ),

                    const SizedBox(width: AppSpacing.md),

                    Expanded(
                      child: Column(
                        crossAxisAlignment:
                            CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Classification Records',
                            style: Theme.of(context)
                                .textTheme
                                .titleSmall
                                ?.copyWith(
                                  color: AppColors.textPrimary,
                                  fontWeight: FontWeight.w700,
                                ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            'Saved classifications are currently available '
                            'during the active app session. Permanent storage '
                            'can be connected when the backend and storage '
                            'integration are added.',
                            style: Theme.of(context)
                                .textTheme
                                .bodySmall
                                ?.copyWith(
                                  color: AppColors.textSecondary,
                                  height: 1.5,
                                ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: AppSpacing.xl),

              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: () {
                    _showResetDialog(
                      context,
                      settingsProvider,
                    );
                  },
                  icon: const Icon(
                    Icons.restart_alt_outlined,
                  ),
                  label: const Text(
                    'Reset Settings',
                  ),
                ),
              ),

              const SizedBox(height: AppSpacing.xl),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
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
            Icons.settings_outlined,
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
                'Settings',
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
                'Customize how gUSo displays and handles classification results.',
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
      ],
    );
  }

  Widget _buildSectionHeader(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String description,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(
          icon,
          color: AppColors.primary,
          size: 21,
        ),

        const SizedBox(width: AppSpacing.sm),

        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: Theme.of(context)
                    .textTheme
                    .titleMedium
                    ?.copyWith(
                      color: AppColors.textPrimary,
                      fontWeight: FontWeight.w700,
                    ),
              ),
              const SizedBox(height: 4),
              Text(
                description,
                style: Theme.of(context)
                    .textTheme
                    .bodySmall
                    ?.copyWith(
                      color: AppColors.textSecondary,
                      height: 1.4,
                    ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildSettingsCard({
    required List<Widget> children,
  }) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(
          AppRadius.large,
        ),
        border: Border.all(
          color: AppColors.borderLight,
        ),
      ),
      child: Column(
        children: children,
      ),
    );
  }

  Widget _buildSwitchTile(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String subtitle,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return Padding(
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Row(
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: AppColors.surfaceDark,
              borderRadius: BorderRadius.circular(
                AppRadius.medium,
              ),
              border: Border.all(
                color: AppColors.borderLight,
              ),
            ),
            child: Icon(
              icon,
              color: AppColors.primary,
              size: 21,
            ),
          ),

          const SizedBox(width: AppSpacing.md),

          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: Theme.of(context)
                      .textTheme
                      .titleSmall
                      ?.copyWith(
                        color: AppColors.textPrimary,
                        fontWeight: FontWeight.w600,
                      ),
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: Theme.of(context)
                      .textTheme
                      .bodySmall
                      ?.copyWith(
                        color: AppColors.textSecondary,
                        height: 1.4,
                      ),
                ),
              ],
            ),
          ),

          const SizedBox(width: AppSpacing.sm),

          Switch(
            value: value,
            onChanged: onChanged,
          ),
        ],
      ),
    );
  }

  Future<void> _showResetDialog(
    BuildContext context,
    SettingsProvider settingsProvider,
  ) async {
    final shouldReset = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          backgroundColor: AppColors.surface,
          title: const Text(
            'Reset settings?',
            style: TextStyle(
              color: AppColors.textPrimary,
            ),
          ),
          content: const Text(
            'All display and classification behavior settings '
            'will return to their default values.',
            style: TextStyle(
              color: AppColors.textSecondary,
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(dialogContext).pop(false);
              },
              child: const Text(
                'Cancel',
              ),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(dialogContext).pop(true);
              },
              child: const Text(
                'Reset',
                style: TextStyle(
                  color: AppColors.primary,
                ),
              ),
            ),
          ],
        );
      },
    );

    if (shouldReset != true) {
      return;
    }

    settingsProvider.resetToDefaults();

    if (!context.mounted) {
      return;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text(
          'Settings restored to defaults.',
        ),
      ),
    );
  }
}