import 'package:flutter/material.dart';

import '../../app/theme.dart';

class LandingFooter extends StatelessWidget {
  const LandingFooter({
    super.key,
    required this.desktopBreakpoint,
    required this.mobileBreakpoint,
    required this.maxContentWidth,
    required this.onHomePressed,
    required this.onAboutPressed,
    required this.onHowItWorksPressed,
    required this.onSeaweedGuidePressed,
    required this.onGetStartedPressed,
  });

  final double desktopBreakpoint;
  final double mobileBreakpoint;
  final double maxContentWidth;

  final VoidCallback onHomePressed;
  final VoidCallback onAboutPressed;
  final VoidCallback onHowItWorksPressed;
  final VoidCallback onSeaweedGuidePressed;
  final VoidCallback onGetStartedPressed;

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

        final verticalPadding = isMobile ? 48.0 : 64.0;

        return Container(
          width: double.infinity,
          decoration: const BoxDecoration(
            color: AppColors.sidebar,
            border: Border(
              top: BorderSide(
                color: AppColors.disabled,
              ),
            ),
          ),
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
                  children: [
                    isDesktop
                        ? Row(
                            crossAxisAlignment:
                                CrossAxisAlignment.start,
                            children: [
                              const Expanded(
                                flex: 5,
                                child: _FooterBrand(),
                              ),
                              const SizedBox(width: 56),
                              Expanded(
                                flex: 3,
                                child: _FooterLinks(
                                  onHomePressed: onHomePressed,
                                  onAboutPressed: onAboutPressed,
                                  onHowItWorksPressed:
                                      onHowItWorksPressed,
                                  onSeaweedGuidePressed:
                                      onSeaweedGuidePressed,
                                ),
                              ),
                              const SizedBox(width: 56),
                              Expanded(
                                flex: 4,
                                child: _FooterAction(
                                  onGetStartedPressed:
                                      onGetStartedPressed,
                                ),
                              ),
                            ],
                          )
                        : Column(
                            crossAxisAlignment:
                                CrossAxisAlignment.start,
                            children: [
                              const _FooterBrand(),
                              const SizedBox(height: 40),
                              _FooterLinks(
                                onHomePressed: onHomePressed,
                                onAboutPressed: onAboutPressed,
                                onHowItWorksPressed:
                                    onHowItWorksPressed,
                                onSeaweedGuidePressed:
                                    onSeaweedGuidePressed,
                              ),
                              const SizedBox(height: 40),
                              _FooterAction(
                                onGetStartedPressed:
                                    onGetStartedPressed,
                              ),
                            ],
                          ),

                    const SizedBox(height: 48),

                    const Divider(),

                    const SizedBox(height: 20),

                    _FooterBottom(
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

class _FooterBrand extends StatelessWidget {
  const _FooterBrand();

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const _FooterLogo(),

        const SizedBox(height: 18),

        ConstrainedBox(
          constraints: const BoxConstraints(
            maxWidth: 430,
          ),
          child: const Text(
            'AI-powered seaweed quality classification and educational '
            'guidance designed around Guso and related seaweed types.',
            style: TextStyle(
              color: AppColors.textSecondary,
              fontSize: 14,
              height: 1.7,
            ),
          ),
        ),
      ],
    );
  }
}

class _FooterLogo extends StatelessWidget {
  const _FooterLogo();

  @override
  Widget build(BuildContext context) {
    return RichText(
      text: const TextSpan(
        children: [
          TextSpan(
            text: 'g',
            style: TextStyle(
              color: AppColors.textPrimary,
              fontSize: 34,
              fontWeight: FontWeight.w800,
              letterSpacing: -2,
            ),
          ),
          TextSpan(
            text: 'US',
            style: TextStyle(
              color: AppColors.primary,
              fontSize: 34,
              fontWeight: FontWeight.w800,
              letterSpacing: -2,
            ),
          ),
          TextSpan(
            text: 'o',
            style: TextStyle(
              color: AppColors.textPrimary,
              fontSize: 34,
              fontWeight: FontWeight.w800,
              letterSpacing: -2,
            ),
          ),
        ],
      ),
    );
  }
}

class _FooterLinks extends StatelessWidget {
  const _FooterLinks({
    required this.onHomePressed,
    required this.onAboutPressed,
    required this.onHowItWorksPressed,
    required this.onSeaweedGuidePressed,
  });

  final VoidCallback onHomePressed;
  final VoidCallback onAboutPressed;
  final VoidCallback onHowItWorksPressed;
  final VoidCallback onSeaweedGuidePressed;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Quick Links',
          style: TextStyle(
            color: AppColors.textPrimary,
            fontSize: 16,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 16),
        _FooterLink(
          label: 'Home',
          onPressed: onHomePressed,
        ),
        _FooterLink(
          label: 'About',
          onPressed: onAboutPressed,
        ),
        _FooterLink(
          label: 'How It Works',
          onPressed: onHowItWorksPressed,
        ),
        _FooterLink(
          label: 'Seaweed Guide',
          onPressed: onSeaweedGuidePressed,
        ),
      ],
    );
  }
}

class _FooterLink extends StatelessWidget {
  const _FooterLink({
    required this.label,
    required this.onPressed,
  });

  final String label;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.centerLeft,
      child: TextButton(
        onPressed: onPressed,
        style: TextButton.styleFrom(
          foregroundColor: AppColors.textSecondary,
          padding: const EdgeInsets.symmetric(
            vertical: 8,
          ),
          minimumSize: Size.zero,
          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
        ),
        child: Text(
          label,
          style: const TextStyle(
            fontSize: 14,
          ),
        ),
      ),
    );
  }
}

class _FooterAction extends StatelessWidget {
  const _FooterAction({
    required this.onGetStartedPressed,
  });

  final VoidCallback onGetStartedPressed;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(22),
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Ready to Explore gUSo?',
            style: TextStyle(
              color: AppColors.textPrimary,
              fontSize: 18,
              fontWeight: FontWeight.w700,
            ),
          ),

          const SizedBox(height: 10),

          const Text(
            'Start using the system or explore the available seaweed '
            'information to learn more.',
            style: TextStyle(
              color: AppColors.textSecondary,
              fontSize: 14,
              height: 1.6,
            ),
          ),

          const SizedBox(height: 20),

          ElevatedButton.icon(
            onPressed: onGetStartedPressed,
            icon: const Icon(
              Icons.arrow_forward_rounded,
            ),
            label: const Text(
              'GET STARTED',
            ),
          ),
        ],
      ),
    );
  }
}

class _FooterBottom extends StatelessWidget {
  const _FooterBottom({
    required this.isMobile,
  });

  final bool isMobile;

  @override
  Widget build(BuildContext context) {
    final copyright = Text(
      '© ${DateTime.now().year} gUSo. All rights reserved.',
      style: const TextStyle(
        color: AppColors.textMuted,
        fontSize: 12,
      ),
    );

    const projectNote = Text(
      'Seaweed Quality Classification & Guide',
      style: TextStyle(
        color: AppColors.textMuted,
        fontSize: 12,
      ),
    );

    if (isMobile) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          copyright,
          const SizedBox(height: 8),
          projectNote,
        ],
      );
    }

    return Row(
      children: [
        copyright,
        const Spacer(),
        projectNote,
      ],
    );
  }
}