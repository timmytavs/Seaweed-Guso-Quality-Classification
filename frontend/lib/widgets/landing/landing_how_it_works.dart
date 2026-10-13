import 'package:flutter/material.dart';

import '../../app/theme.dart';

class LandingHowItWorks extends StatelessWidget {
  const LandingHowItWorks({
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
          color: AppColors.background,
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
                    const _SectionLabel(
                      icon: Icons.route_outlined,
                      label: 'HOW IT WORKS',
                    ),

                    const SizedBox(height: 22),

                    const Text(
                      'From Image to Clear Quality Insights',
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
                        'gUSo keeps the classification process simple. '
                        'Upload a clear seaweed image, let the system analyze '
                        'its visible characteristics, and review the '
                        'structured result.',
                        style: TextStyle(
                          color: AppColors.textSecondary,
                          fontSize: 17,
                          height: 1.7,
                        ),
                      ),
                    ),

                    SizedBox(
                      height: isMobile ? 42 : 56,
                    ),

                    _WorkflowSteps(
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

class _WorkflowSteps extends StatelessWidget {
  const _WorkflowSteps({
    required this.isDesktop,
    required this.isMobile,
  });

  final bool isDesktop;
  final bool isMobile;

  @override
  Widget build(BuildContext context) {
    const steps = [
      _WorkflowStepData(
        number: '01',
        icon: Icons.upload_file_outlined,
        title: 'Upload',
        description:
            'Choose a clear image of the seaweed sample you want to assess.',
      ),
      _WorkflowStepData(
        number: '02',
        icon: Icons.image_search_outlined,
        title: 'Analyze',
        description:
            'The system processes visible image characteristics for classification.',
      ),
      _WorkflowStepData(
        number: '03',
        icon: Icons.analytics_outlined,
        title: 'View Results',
        description:
            'Review quality, freshness, confidence, image condition, and visible traits.',
      ),
      _WorkflowStepData(
        number: '04',
        icon: Icons.bookmark_outline_rounded,
        title: 'Save or Continue',
        description:
            'Save the result for later review or upload another image for assessment.',
      ),
    ];

    if (isDesktop) {
      return Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          for (int index = 0; index < steps.length; index++) ...[
            Expanded(
              child: _WorkflowCard(
                step: steps[index],
              ),
            ),
            if (index != steps.length - 1)
              const SizedBox(width: 20),
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
            for (final step in steps)
              SizedBox(
                width: cardWidth,
                child: _WorkflowCard(
                  step: step,
                ),
              ),
          ],
        );
      },
    );
  }
}

class _WorkflowCard extends StatelessWidget {
  const _WorkflowCard({
    required this.step,
  });

  final _WorkflowStepData step;

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(
        minHeight: 245,
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
          Row(
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
                  step.icon,
                  color: AppColors.primary,
                  size: 25,
                ),
              ),

              const Spacer(),

              Text(
                step.number,
                style: TextStyle(
                  color: AppColors.primary.withValues(
                    alpha: 0.55,
                  ),
                  fontSize: 28,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),

          const SizedBox(height: 26),

          Text(
            step.title,
            style: const TextStyle(
              color: AppColors.textPrimary,
              fontSize: 20,
              fontWeight: FontWeight.w700,
            ),
          ),

          const SizedBox(height: 12),

          Text(
            step.description,
            style: const TextStyle(
              color: AppColors.textSecondary,
              fontSize: 14,
              height: 1.65,
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

class _WorkflowStepData {
  const _WorkflowStepData({
    required this.number,
    required this.icon,
    required this.title,
    required this.description,
  });

  final String number;
  final IconData icon;
  final String title;
  final String description;
}