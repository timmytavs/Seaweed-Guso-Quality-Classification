import 'package:flutter/material.dart';

import '../../app/theme.dart';
import '../../data/seaweed_data.dart';
import '../../models/seaweed_info.dart';
import '../../screens/seaweed_guide/seaweed_detail_screen.dart';
import '../seaweed_guide/seaweed_card.dart';

class LandingSeaweedGuidePreview extends StatelessWidget {
  const LandingSeaweedGuidePreview({
    super.key,
    required this.desktopBreakpoint,
    required this.mobileBreakpoint,
    required this.maxContentWidth,
    required this.onExploreGuidePressed,
  });

  final double desktopBreakpoint;
  final double mobileBreakpoint;
  final double maxContentWidth;

  final VoidCallback onExploreGuidePressed;

  @override
  Widget build(BuildContext context) {
    final previewSeaweeds =
        SeaweedData.seaweeds.take(3).toList();

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
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _SectionHeader(
                      isMobile: isMobile,
                      onExploreGuidePressed:
                          onExploreGuidePressed,
                    ),

                    SizedBox(
                      height: isMobile ? 40 : 52,
                    ),

                    _GuidePreviewGrid(
                      seaweeds: previewSeaweeds,
                      isDesktop: isDesktop,
                      isMobile: isMobile,
                    ),
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

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({
    required this.isMobile,
    required this.onExploreGuidePressed,
  });

  final bool isMobile;
  final VoidCallback onExploreGuidePressed;

  @override
  Widget build(BuildContext context) {
    final introduction = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const _SectionLabel(
          icon: Icons.menu_book_outlined,
          label: 'SEAWEED GUIDE',
        ),

        const SizedBox(height: 22),

        const Text(
          'Learn More About the Seaweeds You Encounter',
          style: TextStyle(
            color: AppColors.textPrimary,
            fontSize: 38,
            height: 1.15,
            fontWeight: FontWeight.w800,
            letterSpacing: -1,
          ),
        ),

        const SizedBox(height: 18),

        ConstrainedBox(
          constraints: const BoxConstraints(
            maxWidth: 760,
          ),
          child: const Text(
            'Explore seaweed types, scientific names, local names, '
            'descriptions, habitats, identification features, and '
            'common uses from the existing gUSo Seaweed Guide.',
            style: TextStyle(
              color: AppColors.textSecondary,
              fontSize: 17,
              height: 1.7,
            ),
          ),
        ),
      ],
    );

    if (isMobile) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          introduction,
          const SizedBox(height: 28),
          OutlinedButton.icon(
            onPressed: onExploreGuidePressed,
            icon: const Icon(
              Icons.arrow_forward_rounded,
            ),
            label: const Text(
              'EXPLORE SEAWEED GUIDE',
            ),
          ),
        ],
      );
    }

    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Expanded(
          child: introduction,
        ),
        const SizedBox(width: 40),
        OutlinedButton.icon(
          onPressed: onExploreGuidePressed,
          icon: const Icon(
            Icons.arrow_forward_rounded,
          ),
          label: const Text(
            'EXPLORE GUIDE',
          ),
        ),
      ],
    );
  }
}

class _GuidePreviewGrid extends StatelessWidget {
  const _GuidePreviewGrid({
    required this.seaweeds,
    required this.isDesktop,
    required this.isMobile,
  });

  final List<SeaweedInfo> seaweeds;
  final bool isDesktop;
  final bool isMobile;

  @override
  Widget build(BuildContext context) {
    if (isDesktop) {
      return Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          for (int index = 0;
              index < seaweeds.length;
              index++) ...[
            Expanded(
              child: SizedBox(
                height: 410,
                child: SeaweedCard(
                  seaweed: seaweeds[index],
                  onTap: () {
                    _openSeaweedDetails(
                      context,
                      seaweeds[index],
                    );
                  },
                ),
              ),
            ),
            if (index != seaweeds.length - 1)
              const SizedBox(width: 22),
          ],
        ],
      );
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        final useTwoColumns =
            !isMobile && constraints.maxWidth >= 700;

        final cardWidth = useTwoColumns
            ? (constraints.maxWidth - 20) / 2
            : constraints.maxWidth;

        return Wrap(
          spacing: 20,
          runSpacing: 20,
          children: [
            for (final seaweed in seaweeds)
              SizedBox(
                width: cardWidth,
                height: useTwoColumns ? 420 : 430,
                child: SeaweedCard(
                  seaweed: seaweed,
                  onTap: () {
                    _openSeaweedDetails(
                      context,
                      seaweed,
                    );
                  },
                ),
              ),
          ],
        );
      },
    );
  }

  void _openSeaweedDetails(
    BuildContext context,
    SeaweedInfo seaweed,
  ) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => SeaweedDetailScreen(
          seaweed: seaweed,
        ),
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