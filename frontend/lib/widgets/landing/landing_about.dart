import 'package:flutter/material.dart';

import '../../app/theme.dart';

class LandingAbout extends StatelessWidget {
  const LandingAbout({
    super.key,
    required this.desktopBreakpoint,
    required this.mobileBreakpoint,
    required this.maxContentWidth,
  });

  final double desktopBreakpoint;
  final double mobileBreakpoint;
  final double maxContentWidth;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;

        final isDesktop = width >= desktopBreakpoint;
        final isMobile = width < mobileBreakpoint;

        final horizontalPadding = isDesktop
            ? 64.0
            : isMobile
                ? 20.0
                : 36.0;

        final verticalPadding = isMobile ? 64.0 : 96.0;

        return Container(
          width: double.infinity,
          color: AppColors.surfaceDark,
          child: Center(
            child: ConstrainedBox(
              constraints: BoxConstraints(
                maxWidth: maxContentWidth,
              ),
              child: Padding(
                padding: EdgeInsets.symmetric(
                  horizontal: horizontalPadding,
                  vertical: verticalPadding,
                ),
                child: isDesktop
                    ? const Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            flex: 8,
                            child: _AboutIntroduction(),
                          ),
                          SizedBox(width: 64),
                          Expanded(
                            flex: 10,
                            child: _AboutFeatureGrid(),
                          ),
                        ],
                      )
                    : const Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _AboutIntroduction(),
                          SizedBox(height: 48),
                          _AboutFeatureGrid(),
                        ],
                      ),
              ),
            ),
          ),
        );
      },
    );
  }
}

class _AboutIntroduction extends StatelessWidget {
  const _AboutIntroduction();

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const _SectionLabel(
          icon: Icons.info_outline_rounded,
          label: 'ABOUT GUSO',
        ),

        const SizedBox(height: 22),

        const Text(
          'A Smarter Way to Understand Seaweed Quality',
          style: TextStyle(
            color: AppColors.textPrimary,
            fontSize: 38,
            height: 1.15,
            fontWeight: FontWeight.w800,
            letterSpacing: -1,
          ),
        ),

        const SizedBox(height: 24),

        const Text(
          'gUSo is designed to help users examine visible qualities '
          'of seaweed through image-based analysis. The system '
          'presents clear and structured information that is easier '
          'to understand at a glance.',
          style: TextStyle(
            color: AppColors.textSecondary,
            fontSize: 17,
            height: 1.7,
          ),
        ),

        const SizedBox(height: 18),

        const Text(
          'Instead of overwhelming users with technical details, '
          'gUSo focuses on practical visual results such as quality, '
          'freshness, image condition, and observable characteristics.',
          style: TextStyle(
            color: AppColors.textSecondary,
            fontSize: 17,
            height: 1.7,
          ),
        ),

        const SizedBox(height: 32),

        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(
              AppRadius.large,
            ),
            border: Border.all(
              color: AppColors.borderPrimary.withValues(
                alpha: 0.35,
              ),
            ),
          ),
          child: const Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(
                Icons.science_outlined,
                color: AppColors.primary,
                size: 28,
              ),
              SizedBox(width: 14),
              Expanded(
                child: Text(
                  'Built around a clean, research-oriented experience '
                  'for seaweed quality assessment and learning.',
                  style: TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 15,
                    height: 1.6,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _AboutFeatureGrid extends StatelessWidget {
  const _AboutFeatureGrid();

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final useTwoColumns = constraints.maxWidth >= 560;

        final cardWidth = useTwoColumns
            ? (constraints.maxWidth - 20) / 2
            : constraints.maxWidth;

        return Wrap(
          spacing: 20,
          runSpacing: 20,
          children: [
            SizedBox(
              width: cardWidth,
              child: const _AboutFeatureCard(
                icon: Icons.image_search_outlined,
                title: 'Image-Based Analysis',
                description:
                    'Use a seaweed image as the starting point for '
                    'structured quality assessment.',
              ),
            ),
            SizedBox(
              width: cardWidth,
              child: const _AboutFeatureCard(
                icon: Icons.eco_outlined,
                title: 'Quality & Freshness',
                description:
                    'View simplified indicators that help describe '
                    'the visible condition of the seaweed sample.',
              ),
            ),
            SizedBox(
              width: cardWidth,
              child: const _AboutFeatureCard(
                icon: Icons.visibility_outlined,
                title: 'Observable Characteristics',
                description:
                    'See image-derived traits such as color, visual '
                    'texture, and other visible characteristics.',
              ),
            ),
            SizedBox(
              width: cardWidth,
              child: const _AboutFeatureCard(
                icon: Icons.menu_book_outlined,
                title: 'Seaweed Guide',
                description:
                    'Explore educational seaweed information through '
                    'an organized and image-focused guide.',
              ),
            ),
          ],
        );
      },
    );
  }
}

class _AboutFeatureCard extends StatelessWidget {
  const _AboutFeatureCard({
    required this.icon,
    required this.title,
    required this.description,
  });

  final IconData icon;
  final String title;
  final String description;

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(
        minHeight: 210,
      ),
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(
          AppRadius.large,
        ),
        border: Border.all(
          color: AppColors.disabled,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: AppColors.primaryDark,
              borderRadius: BorderRadius.circular(
                AppRadius.medium,
              ),
            ),
            child: Icon(
              icon,
              color: AppColors.primary,
              size: 25,
            ),
          ),

          const SizedBox(height: 22),

          Text(
            title,
            style: const TextStyle(
              color: AppColors.textPrimary,
              fontSize: 18,
              fontWeight: FontWeight.w700,
            ),
          ),

          const SizedBox(height: 12),

          Text(
            description,
            style: const TextStyle(
              color: AppColors.textSecondary,
              fontSize: 14,
              height: 1.6,
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionLabel extends StatelessWidget {
  const _SectionLabel({
    required this.icon,
    required this.label,
  });

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 14,
        vertical: 8,
      ),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(
          AppRadius.extraLarge,
        ),
        border: Border.all(
          color: AppColors.primary.withValues(
            alpha: 0.35,
          ),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            color: AppColors.primary,
            size: 18,
          ),
          const SizedBox(width: 8),
          Text(
            label,
            style: const TextStyle(
              color: AppColors.primary,
              fontSize: 12,
              fontWeight: FontWeight.bold,
              letterSpacing: 1,
            ),
          ),
        ],
      ),
    );
  }
}