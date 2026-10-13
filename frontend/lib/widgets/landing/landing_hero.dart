import 'package:flutter/material.dart';

import '../../app/theme.dart';
import 'landing_login_form.dart';
import 'landing_register_form.dart';

enum LandingHeroView {
  preview,
  login,
  register,
}

class LandingHero extends StatelessWidget {
  const LandingHero({
    super.key,
    required this.desktopBreakpoint,
    required this.mobileBreakpoint,
    required this.maxContentWidth,
    required this.onGetStartedPressed,
    required this.onExploreGuidePressed,
    required this.authView,
    required this.onLoginSubmitted,
    required this.onRegisterSubmitted,
    required this.onShowLogin,
    required this.onShowRegister,
    required this.onBackToPreview,
  });

  final double desktopBreakpoint;
  final double mobileBreakpoint;
  final double maxContentWidth;

  final VoidCallback onGetStartedPressed;
  final VoidCallback onExploreGuidePressed;

  final LandingHeroView authView;

  final void Function(
    String identifier,
    String password,
  ) onLoginSubmitted;

  final void Function(
    String firstName,
    String lastName,
    String email,
    String contactNumber,
    String password,
    String confirmPassword,
  ) onRegisterSubmitted;

  final VoidCallback onShowLogin;
  final VoidCallback onShowRegister;
  final VoidCallback onBackToPreview;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;

        final isDesktop =
            width >= desktopBreakpoint;

        final isMobile =
            width < mobileBreakpoint;

        final horizontalPadding = isDesktop
            ? 64.0
            : isMobile
                ? 20.0
                : 36.0;

        final verticalPadding =
            isMobile ? 54.0 : 82.0;

        return Center(
          child: ConstrainedBox(
            constraints: BoxConstraints(
              maxWidth: maxContentWidth,
            ),
            child: Padding(
              padding: EdgeInsets.fromLTRB(
                horizontalPadding,
                verticalPadding,
                horizontalPadding,
                isMobile ? 70 : 110,
              ),
              child: isDesktop
                  ? Row(
                      crossAxisAlignment:
                          CrossAxisAlignment.center,
                      children: [
                        Expanded(
                          flex: 11,
                          child: _HeroContent(
                            onGetStartedPressed:
                                onGetStartedPressed,
                            onExploreGuidePressed:
                                onExploreGuidePressed,
                          ),
                        ),

                        const SizedBox(width: 70),

                        Expanded(
                          flex: 9,
                          child: _HeroPanel(
                            compact: false,
                            authView: authView,
                            onLoginSubmitted:
                                onLoginSubmitted,
                            onRegisterSubmitted:
                                onRegisterSubmitted,
                            onShowLogin:
                                onShowLogin,
                            onShowRegister:
                                onShowRegister,
                            onBackToPreview:
                                onBackToPreview,
                          ),
                        ),
                      ],
                    )
                  : Column(
                      crossAxisAlignment:
                          CrossAxisAlignment.stretch,
                      children: [
                        _HeroContent(
                          onGetStartedPressed:
                              onGetStartedPressed,
                          onExploreGuidePressed:
                              onExploreGuidePressed,
                        ),

                        SizedBox(
                          height:
                              isMobile ? 48 : 64,
                        ),

                        _HeroPanel(
                          compact: isMobile,
                          authView: authView,
                          onLoginSubmitted:
                              onLoginSubmitted,
                          onRegisterSubmitted:
                              onRegisterSubmitted,
                          onShowLogin:
                              onShowLogin,
                          onShowRegister:
                              onShowRegister,
                          onBackToPreview:
                              onBackToPreview,
                        ),
                      ],
                    ),
            ),
          ),
        );
      },
    );
  }
}

class _HeroContent extends StatelessWidget {
  const _HeroContent({
    required this.onGetStartedPressed,
    required this.onExploreGuidePressed,
  });

  final VoidCallback onGetStartedPressed;
  final VoidCallback onExploreGuidePressed;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final availableWidth =
            constraints.maxWidth;

        double headlineSize;

        if (availableWidth >= 650) {
          headlineSize = 64;
        } else if (availableWidth >= 450) {
          headlineSize = 50;
        } else {
          headlineSize = 40;
        }

        return Column(
          crossAxisAlignment:
              CrossAxisAlignment.start,
          children: [
            Container(
              padding:
                  const EdgeInsets.symmetric(
                horizontal: 14,
                vertical: 8,
              ),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius:
                    BorderRadius.circular(
                  AppRadius.extraLarge,
                ),
                border: Border.all(
                  color: AppColors.borderPrimary
                      .withValues(
                    alpha: 0.45,
                  ),
                ),
              ),
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.eco_outlined,
                    color: AppColors.primary,
                    size: 18,
                  ),
                  SizedBox(width: 8),
                  Text(
                    'AI-POWERED SEAWEED ANALYSIS',
                    style: TextStyle(
                      color: AppColors.primary,
                      fontSize: 12,
                      fontWeight:
                          FontWeight.bold,
                      letterSpacing: 1,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            Text.rich(
              TextSpan(
                children: [
                  const TextSpan(
                    text:
                        'Know Your Guso.\n',
                  ),
                  const TextSpan(
                    text:
                        'Understand Its Quality.',
                    style: TextStyle(
                      color:
                          AppColors.primary,
                    ),
                  ),
                ],
              ),
              style: TextStyle(
                color:
                    AppColors.textPrimary,
                fontSize: headlineSize,
                height: 1.04,
                fontWeight:
                    FontWeight.w800,
                letterSpacing: -1.8,
              ),
            ),

            const SizedBox(height: 26),

            ConstrainedBox(
              constraints:
                  const BoxConstraints(
                maxWidth: 650,
              ),
              child: const Text(
                'Upload an image of seaweed and receive structured '
                'insights about its quality, freshness, image condition, '
                'and observable characteristics.',
                style: TextStyle(
                  color:
                      AppColors.textSecondary,
                  fontSize: 18,
                  height: 1.65,
                ),
              ),
            ),

            const SizedBox(height: 36),

            Wrap(
              spacing: 14,
              runSpacing: 14,
              children: [
                ElevatedButton.icon(
                  onPressed:
                      onGetStartedPressed,
                  icon: const Icon(
                    Icons
                        .arrow_forward_rounded,
                  ),
                  label: const Text(
                    'GET STARTED',
                  ),
                ),
                OutlinedButton.icon(
                  onPressed:
                      onExploreGuidePressed,
                  icon: const Icon(
                    Icons
                        .menu_book_outlined,
                  ),
                  label: const Text(
                    'EXPLORE SEAWEED GUIDE',
                  ),
                ),
              ],
            ),

            const SizedBox(height: 34),

            const Wrap(
              spacing: 28,
              runSpacing: 16,
              children: [
                _HeroMiniFeature(
                  icon: Icons
                      .photo_camera_outlined,
                  label:
                      'Image-based analysis',
                ),
                _HeroMiniFeature(
                  icon:
                      Icons.spa_outlined,
                  label:
                      'Quality & freshness',
                ),
                _HeroMiniFeature(
                  icon:
                      Icons.science_outlined,
                  label:
                      'Research-oriented',
                ),
              ],
            ),
          ],
        );
      },
    );
  }
}

class _HeroMiniFeature
    extends StatelessWidget {
  const _HeroMiniFeature({
    required this.icon,
    required this.label,
  });

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(
          icon,
          color: AppColors.primary,
          size: 19,
        ),
        const SizedBox(width: 8),
        Text(
          label,
          style: const TextStyle(
            color:
                AppColors.textSecondary,
            fontSize: 14,
          ),
        ),
      ],
    );
  }
}

class _HeroPanel extends StatelessWidget {
  const _HeroPanel({
    required this.compact,
    required this.authView,
    required this.onLoginSubmitted,
    required this.onRegisterSubmitted,
    required this.onShowLogin,
    required this.onShowRegister,
    required this.onBackToPreview,
  });

  final bool compact;
  final LandingHeroView authView;

  final void Function(
    String identifier,
    String password,
  ) onLoginSubmitted;

  final void Function(
    String firstName,
    String lastName,
    String email,
    String contactNumber,
    String password,
    String confirmPassword,
  ) onRegisterSubmitted;

  final VoidCallback onShowLogin;
  final VoidCallback onShowRegister;
  final VoidCallback onBackToPreview;

  @override
  Widget build(BuildContext context) {
    final panelHeight =
        compact ? 660.0 : 600.0;

    return SizedBox(
      width: double.infinity,
      height: panelHeight,
      child: AnimatedSwitcher(
        duration: const Duration(
          milliseconds: 450,
        ),
        switchInCurve:
            Curves.easeOutCubic,
        switchOutCurve:
            Curves.easeInCubic,

        layoutBuilder: (
          Widget? currentChild,
          List<Widget> previousChildren,
        ) {
          return Stack(
            fit: StackFit.expand,
            children: [
              ...previousChildren,
              ?currentChild,
            ],
          );
        },

        transitionBuilder: (
          Widget child,
          Animation<double> animation,
        ) {
          final slideAnimation =
              Tween<Offset>(
            begin:
                const Offset(0.10, 0),
            end: Offset.zero,
          ).animate(
            CurvedAnimation(
              parent: animation,
              curve:
                  Curves.easeOutCubic,
            ),
          );

          return FadeTransition(
            opacity: animation,
            child: SlideTransition(
              position: slideAnimation,
              child: child,
            ),
          );
        },

        child: _buildCurrentView(),
      ),
    );
  }

  Widget _buildCurrentView() {
    switch (authView) {
      case LandingHeroView.preview:
        return const _HeroVisual(
          key: ValueKey(
            'landing-preview',
          ),
        );

      case LandingHeroView.login:
        return LandingLoginForm(
          key: const ValueKey(
            'landing-login',
          ),
          onLoginPressed:
              onLoginSubmitted,
          onBackPressed:
              onBackToPreview,
          onRegisterPressed:
              onShowRegister,
        );

      case LandingHeroView.register:
        return LandingRegisterForm(
          key: const ValueKey(
            'landing-register',
          ),
          onRegisterPressed:
              onRegisterSubmitted,
          onBackPressed:
              onBackToPreview,
          onLoginPressed:
              onShowLogin,
        );
    }
  }
}

class _HeroVisual extends StatelessWidget {
  const _HeroVisual({
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      height: double.infinity,
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius:
            BorderRadius.circular(
          AppRadius.extraLarge,
        ),
        border: Border.all(
          color:
              AppColors.borderPrimary,
          width: 1.5,
        ),
      ),
      child: ClipRRect(
        borderRadius:
            BorderRadius.circular(
          AppRadius.extraLarge - 2,
        ),
        child: Stack(
          fit: StackFit.expand,
          children: [
            Image.asset(
              'images/landing_sample_result.png',
              fit: BoxFit.cover,
              alignment:
                  Alignment.topCenter,
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
                        Icons
                            .image_not_supported_outlined,
                        color:
                            AppColors.textMuted,
                        size: 52,
                      ),
                      SizedBox(height: 12),
                      Text(
                        'Sample result image not available',
                        style: TextStyle(
                          color:
                              AppColors.textMuted,
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),

            const Positioned.fill(
              child: IgnorePointer(
                child: DecoratedBox(
                  decoration:
                      BoxDecoration(
                    gradient:
                        LinearGradient(
                      begin:
                          Alignment.topCenter,
                      end:
                          Alignment.bottomCenter,
                      colors: [
                        Colors.transparent,
                        Color(0x11001000),
                        Color(0x66001000),
                      ],
                      stops: [
                        0.0,
                        0.68,
                        1.0,
                      ],
                    ),
                  ),
                ),
              ),
            ),

            Positioned(
              left: 22,
              right: 22,
              bottom: 22,
              child: Container(
                padding:
                    const EdgeInsets.symmetric(
                  horizontal: 18,
                  vertical: 14,
                ),
                decoration: BoxDecoration(
                  color: AppColors.surfaceDark
                      .withValues(
                    alpha: 0.94,
                  ),
                  borderRadius:
                      BorderRadius.circular(
                    AppRadius.large,
                  ),
                  border: Border.all(
                    color: AppColors.primary
                        .withValues(
                      alpha: 0.45,
                    ),
                  ),
                ),
                child: const Row(
                  children: [
                    Icon(
                      Icons
                          .check_circle_outline_rounded,
                      color:
                          AppColors.primary,
                      size: 22,
                    ),
                    SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'Sample classification result from the gUSo system',
                        style: TextStyle(
                          color: AppColors
                              .textPrimary,
                          fontSize: 14,
                          fontWeight:
                              FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}