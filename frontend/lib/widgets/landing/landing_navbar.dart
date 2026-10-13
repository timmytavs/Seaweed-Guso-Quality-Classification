import 'package:flutter/material.dart';

import '../../app/theme.dart';

class LandingNavbar extends StatelessWidget {
  const LandingNavbar({
    super.key,
    required this.onHomePressed,
    required this.onAboutPressed,
    required this.onHowItWorksPressed,
    required this.onSeaweedGuidePressed,
    required this.onLoginPressed,
    this.desktopBreakpoint = 1200,
    this.mobileBreakpoint = 768,
    this.maxContentWidth = 1440,
  });

  final VoidCallback onHomePressed;
  final VoidCallback onAboutPressed;
  final VoidCallback onHowItWorksPressed;
  final VoidCallback onSeaweedGuidePressed;
  final VoidCallback onLoginPressed;

  final double desktopBreakpoint;
  final double mobileBreakpoint;
  final double maxContentWidth;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;

        final isMobile = width < mobileBreakpoint;
        final isDesktop = width >= desktopBreakpoint;

        final horizontalPadding = isDesktop
            ? 64.0
            : isMobile
                ? 20.0
                : 36.0;

        return Center(
          child: ConstrainedBox(
            constraints: BoxConstraints(
              maxWidth: maxContentWidth,
            ),
            child: Padding(
              padding: EdgeInsets.symmetric(
                horizontal: horizontalPadding,
                vertical: 22,
              ),
              child: Row(
                children: [
                  const _GusoLogo(),

                  const Spacer(),

                  if (!isMobile) ...[
                    _NavbarLink(
                      label: 'Home',
                      onPressed: onHomePressed,
                    ),
                    _NavbarLink(
                      label: 'About',
                      onPressed: onAboutPressed,
                    ),
                    _NavbarLink(
                      label: 'How It Works',
                      onPressed: onHowItWorksPressed,
                    ),
                    _NavbarLink(
                      label: 'Seaweed Guide',
                      onPressed: onSeaweedGuidePressed,
                    ),
                    const SizedBox(width: 24),
                  ],

                  _LoginButton(
                    onPressed: onLoginPressed,
                    compact: isMobile,
                  ),

                  if (isMobile) ...[
                    const SizedBox(width: 8),
                    _MobileMenu(
                      onHomePressed: onHomePressed,
                      onAboutPressed: onAboutPressed,
                      onHowItWorksPressed: onHowItWorksPressed,
                      onSeaweedGuidePressed: onSeaweedGuidePressed,
                    ),
                  ],
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

class _GusoLogo extends StatelessWidget {
  const _GusoLogo();

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: 'gUSo',
      child: RichText(
        text: const TextSpan(
          children: [
            TextSpan(
              text: 'g',
              style: TextStyle(
                color: AppColors.textPrimary,
                fontSize: 38,
                fontWeight: FontWeight.w800,
                letterSpacing: -2,
              ),
            ),
            TextSpan(
              text: 'US',
              style: TextStyle(
                color: AppColors.primary,
                fontSize: 38,
                fontWeight: FontWeight.w800,
                letterSpacing: -2,
              ),
            ),
            TextSpan(
              text: 'o',
              style: TextStyle(
                color: AppColors.textPrimary,
                fontSize: 38,
                fontWeight: FontWeight.w800,
                letterSpacing: -2,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _NavbarLink extends StatelessWidget {
  const _NavbarLink({
    required this.label,
    required this.onPressed,
  });

  final String label;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: 6,
      ),
      child: TextButton(
        onPressed: onPressed,
        style: TextButton.styleFrom(
          foregroundColor: AppColors.textSecondary,
          overlayColor: AppColors.primary.withValues(
            alpha: 0.08,
          ),
          padding: const EdgeInsets.symmetric(
            horizontal: 14,
            vertical: 12,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(
              AppRadius.small,
            ),
          ),
          textStyle: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w500,
          ),
        ),
        child: Text(label),
      ),
    );
  }
}

class _LoginButton extends StatelessWidget {
  const _LoginButton({
    required this.onPressed,
    required this.compact,
  });

  final VoidCallback onPressed;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    return ElevatedButton(
      onPressed: onPressed,
      style: ButtonStyle(
        elevation: const WidgetStatePropertyAll(0),

        backgroundColor:
            WidgetStateProperty.resolveWith<Color>(
          (states) {
            if (states.contains(WidgetState.hovered)) {
              return Colors.white;
            }

            return AppColors.primary;
          },
        ),

        foregroundColor:
            const WidgetStatePropertyAll(
          Colors.black,
        ),

        padding:
            WidgetStatePropertyAll(
          EdgeInsets.symmetric(
            horizontal: compact ? 20 : 28,
            vertical: 14,
          ),
        ),

        shape:
            WidgetStatePropertyAll(
          RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(
              AppRadius.medium,
            ),
          ),
        ),

        textStyle:
            const WidgetStatePropertyAll(
          TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      child: const Text('LOGIN'),
    );
  }
}

class _MobileMenu extends StatelessWidget {
  const _MobileMenu({
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
    return PopupMenuButton<_LandingMenuItem>(
      tooltip: 'Open navigation menu',
      color: AppColors.surface,
      surfaceTintColor: AppColors.surface,
      icon: const Icon(
        Icons.menu_rounded,
        color: AppColors.textPrimary,
        size: 28,
      ),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(
          AppRadius.medium,
        ),
        side: const BorderSide(
          color: AppColors.disabled,
        ),
      ),
      onSelected: (item) {
        switch (item) {
          case _LandingMenuItem.home:
            onHomePressed();
            break;

          case _LandingMenuItem.about:
            onAboutPressed();
            break;

          case _LandingMenuItem.howItWorks:
            onHowItWorksPressed();
            break;

          case _LandingMenuItem.seaweedGuide:
            onSeaweedGuidePressed();
            break;
        }
      },
      itemBuilder: (context) {
        return const [
          PopupMenuItem(
            value: _LandingMenuItem.home,
            child: _MobileMenuEntry(
              icon: Icons.home_outlined,
              label: 'Home',
            ),
          ),
          PopupMenuItem(
            value: _LandingMenuItem.about,
            child: _MobileMenuEntry(
              icon: Icons.info_outline_rounded,
              label: 'About',
            ),
          ),
          PopupMenuItem(
            value: _LandingMenuItem.howItWorks,
            child: _MobileMenuEntry(
              icon: Icons.route_outlined,
              label: 'How It Works',
            ),
          ),
          PopupMenuItem(
            value: _LandingMenuItem.seaweedGuide,
            child: _MobileMenuEntry(
              icon: Icons.menu_book_outlined,
              label: 'Seaweed Guide',
            ),
          ),
        ];
      },
    );
  }
}

class _MobileMenuEntry extends StatelessWidget {
  const _MobileMenuEntry({
    required this.icon,
    required this.label,
  });

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(
          icon,
          color: AppColors.primary,
          size: 21,
        ),
        const SizedBox(width: 12),
        Text(
          label,
          style: const TextStyle(
            color: AppColors.textPrimary,
            fontSize: 15,
          ),
        ),
      ],
    );
  }
}

enum _LandingMenuItem {
  home,
  about,
  howItWorks,
  seaweedGuide,
}