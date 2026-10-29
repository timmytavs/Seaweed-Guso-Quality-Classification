import 'package:flutter/material.dart';

import '../../app/theme.dart';
import '../../screens/seaweed_guide/seaweed_guide_screen.dart';
import '../../services/auth_service.dart';
import '../home/home_screen.dart';

import '../../widgets/landing/landing_about.dart';
import '../../widgets/landing/landing_footer.dart';
import '../../widgets/landing/landing_hero.dart';
import '../../widgets/landing/landing_how_it_works.dart';
import '../../widgets/landing/landing_navbar.dart';
import '../../widgets/landing/landing_seaweed_guide_preview.dart';

import 'forgot_password_screen.dart';

class LandingScreen extends StatefulWidget {
  const LandingScreen({super.key});

  @override
  State<LandingScreen> createState() => _LandingScreenState();
}

class _LandingScreenState extends State<LandingScreen> {
  static const double _desktopBreakpoint = 1200;
  static const double _mobileBreakpoint = 768;
  static const double _maxContentWidth = 1440;
  static const double _navbarHeight = 92;

  final ScrollController _scrollController = ScrollController();

  final GlobalKey _homeKey = GlobalKey();
  final GlobalKey _aboutKey = GlobalKey();
  final GlobalKey _howItWorksKey = GlobalKey();
  final GlobalKey _seaweedGuideKey = GlobalKey();

  LandingHeroView _authView =
      LandingHeroView.preview;

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color.fromARGB(255, 2, 76, 2),
              Color(0xFF062408),
              Color(0xFF001000),
            ],
            stops: [
              0.0,
              0.48,
              1.0,
            ],
          ),
        ),
        child: SafeArea(
          child: Stack(
            children: [
              Positioned.fill(
                child: SingleChildScrollView(
                  controller: _scrollController,
                  padding: const EdgeInsets.only(
                    top: _navbarHeight,
                  ),
                  child: Column(
                    children: [
                      KeyedSubtree(
                        key: _homeKey,
                        child: LandingHero(
                          desktopBreakpoint:
                              _desktopBreakpoint,
                          mobileBreakpoint:
                              _mobileBreakpoint,
                          maxContentWidth:
                              _maxContentWidth,

                          onGetStartedPressed:
                              _openRegisterPanel,

                          onExploreGuidePressed:
                              _openSeaweedGuide,

                          authView: _authView,

                          onLoginSubmitted: (
                            identifier,
                            password,
                          ) {
                            _handleLoginSubmission(
                              identifier,
                              password,
                            );
                          },

                          onRegisterSubmitted: (
                            firstName,
                            lastName,
                            email,
                            contactNumber,
                            password,
                            confirmPassword,
                          ) {
                            _handleRegisterSubmission(
                              firstName,
                              lastName,
                              email,
                              contactNumber,
                              password,
                              confirmPassword,
                            );
                          },

                          onShowLogin:
                              _showLoginPanel,

                          onForgotPasswordPressed:
                              _openForgotPassword,

                          onShowRegister:
                              _showRegisterPanel,

                          onBackToPreview:
                              _showPreviewPanel,
                        ),
                      ),

                      KeyedSubtree(
                        key: _aboutKey,
                        child: const LandingAbout(
                          desktopBreakpoint:
                              _desktopBreakpoint,
                          mobileBreakpoint:
                              _mobileBreakpoint,
                          maxContentWidth:
                              _maxContentWidth,
                        ),
                      ),

                      KeyedSubtree(
                        key: _howItWorksKey,
                        child: const LandingHowItWorks(
                          desktopBreakpoint:
                              _desktopBreakpoint,
                          mobileBreakpoint:
                              _mobileBreakpoint,
                          maxContentWidth:
                              _maxContentWidth,
                        ),
                      ),

                      KeyedSubtree(
                        key: _seaweedGuideKey,
                        child:
                            LandingSeaweedGuidePreview(
                          desktopBreakpoint:
                              _desktopBreakpoint,
                          mobileBreakpoint:
                              _mobileBreakpoint,
                          maxContentWidth:
                              _maxContentWidth,
                          onExploreGuidePressed:
                              _openSeaweedGuide,
                        ),
                      ),

                      LandingFooter(
                        desktopBreakpoint:
                            _desktopBreakpoint,
                        mobileBreakpoint:
                            _mobileBreakpoint,
                        maxContentWidth:
                            _maxContentWidth,

                        onHomePressed:
                            _returnToHome,

                        onAboutPressed: () {
                          _scrollToSection(
                            _aboutKey,
                          );
                        },

                        onHowItWorksPressed: () {
                          _scrollToSection(
                            _howItWorksKey,
                          );
                        },

                        onSeaweedGuidePressed: () {
                          _scrollToSection(
                            _seaweedGuideKey,
                          );
                        },

                        onGetStartedPressed:
                            _openRegisterPanel,
                      ),
                    ],
                  ),
                ),
              ),

              Positioned(
                top: 0,
                left: 0,
                right: 0,
                child: Container(
                  decoration: BoxDecoration(
                    color: AppColors.background,
                    border: Border(
                      bottom: BorderSide(
                        color:
                            AppColors.disabled
                                .withValues(
                          alpha: 0.55,
                        ),
                      ),
                    ),
                  ),
                  child: LandingNavbar(
                    desktopBreakpoint:
                        _desktopBreakpoint,
                    mobileBreakpoint:
                        _mobileBreakpoint,
                    maxContentWidth:
                        _maxContentWidth,

                    onHomePressed:
                        _returnToHome,

                    onAboutPressed: () {
                      _scrollToSection(
                        _aboutKey,
                      );
                    },

                    onHowItWorksPressed: () {
                      _scrollToSection(
                        _howItWorksKey,
                      );
                    },

                    onSeaweedGuidePressed: () {
                      _scrollToSection(
                        _seaweedGuideKey,
                      );
                    },

                    onLoginPressed:
                        _openLoginPanel,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _openLoginPanel() {
    _setAuthView(
      LandingHeroView.login,
    );
  }

  void _openRegisterPanel() {
    _setAuthView(
      LandingHeroView.register,
    );
  }

  void _showLoginPanel() {
    _setAuthView(
      LandingHeroView.login,
    );
  }

  void _showRegisterPanel() {
    _setAuthView(
      LandingHeroView.register,
    );
  }

  void _showPreviewPanel() {
    if (_authView ==
        LandingHeroView.preview) {
      return;
    }

    setState(() {
      _authView =
          LandingHeroView.preview;
    });
  }

  void _setAuthView(
    LandingHeroView view,
  ) {
    if (_authView != view) {
      setState(() {
        _authView = view;
      });
    }

    WidgetsBinding.instance
        .addPostFrameCallback((_) {
      if (!mounted) {
        return;
      }

      _scrollToSection(
        _homeKey,
      );
    });
  }

  void _returnToHome() {
    if (_authView !=
        LandingHeroView.preview) {
      setState(() {
        _authView =
            LandingHeroView.preview;
      });
    }

    WidgetsBinding.instance
        .addPostFrameCallback((_) {
      if (!mounted) {
        return;
      }

      _scrollToSection(
        _homeKey,
      );
    });
  }

  Future<void> _handleLoginSubmission(
    String identifier,
    String password,
  ) async {
    if (identifier.trim().isEmpty || password.isEmpty) {
      _showMessage(
        'Please enter your email or contact number and password.',
      );
      return;
    }

    try {
      // AuthService logs in with FastAPI, receives the JWT, and persists it
      // so the user can resume the session after refreshing Chrome.
      await const AuthService().login(
        identifier: identifier.trim(),
        password: password,
      );

      if (!mounted) return;

      // Release the active login TextField before navigating away.
      FocusManager.instance.primaryFocus?.unfocus();
      Navigator.of(context).pushReplacement(
        MaterialPageRoute<void>(
          builder: (_) => const HomeScreen(),
        ),
      );
    } catch (error) {
      if (!mounted) return;
      _showMessage(error.toString().replaceFirst('Exception: ', ''));
    }
  }

  void _handleRegisterSubmission(
    String firstName,
    String lastName,
    String email,
    String contactNumber,
    String password,
    String confirmPassword,
  ) {
    if (firstName.isEmpty) {
      _showMessage(
        'Please enter your first name.',
      );
      return;
    }

    if (lastName.isEmpty) {
      _showMessage(
        'Please enter your last name.',
      );
      return;
    }

    if (contactNumber.isEmpty) {
      _showMessage(
        'Please enter your contact number.',
      );
      return;
    }

    if (email.isNotEmpty &&
        !_looksLikeEmail(email)) {
      _showMessage(
        'Please enter a valid email address or leave it blank.',
      );
      return;
    }

    if (password.isEmpty) {
      _showMessage(
        'Please create a password.',
      );
      return;
    }

    if (confirmPassword.isEmpty) {
      _showMessage(
        'Please confirm your password.',
      );
      return;
    }

    if (password !=
        confirmPassword) {
      _showMessage(
        'Passwords do not match.',
      );
      return;
    }

    _showMessage(
      'Registration backend will be connected later.',
    );
  }

  bool _looksLikeEmail(
    String email,
  ) {
    final emailPattern = RegExp(
      r'^[^@\s]+@[^@\s]+\.[^@\s]+$',
    );

    return emailPattern
        .hasMatch(email);
  }

  void _showMessage(
    String message,
  ) {
    ScaffoldMessenger.of(context)
        .showSnackBar(
      SnackBar(
        content: Text(
          message,
        ),
      ),
    );
  }

  Future<void> _scrollToSection(
    GlobalKey key,
  ) async {
    final sectionContext =
        key.currentContext;

    if (sectionContext == null ||
        !_scrollController.hasClients) {
      return;
    }

    final renderObject =
        sectionContext.findRenderObject();

    if (renderObject is! RenderBox) {
      return;
    }

    final sectionPosition =
        renderObject
            .localToGlobal(
              Offset.zero,
            )
            .dy;

    final targetOffset =
        _scrollController.offset +
        sectionPosition -
        _navbarHeight -
        12;

    final safeOffset =
        targetOffset.clamp(
      0.0,
      _scrollController
          .position
          .maxScrollExtent,
    );

    await _scrollController
        .animateTo(
      safeOffset,
      duration: const Duration(
        milliseconds: 550,
      ),
      curve:
          Curves.easeInOutCubic,
    );
  }

  void _openSeaweedGuide() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (
          routeContext,
        ) {
          return Scaffold(
            backgroundColor:
                AppColors.background,
            body: SafeArea(
              child: Column(
                children: [
                  Padding(
                    padding:
                        const EdgeInsets
                            .fromLTRB(
                      28,
                      20,
                      28,
                      0,
                    ),
                    child: Align(
                      alignment:
                          Alignment
                              .centerLeft,
                      child:
                          TextButton.icon(
                        onPressed: () {
                          Navigator.of(
                            routeContext,
                          ).pop();
                        },
                        icon: const Icon(
                          Icons
                              .arrow_back_rounded,
                        ),
                        label:
                            const Text(
                          'Back to Landing Page',
                        ),
                      ),
                    ),
                  ),
                  const Expanded(
                    child:
                        SeaweedGuideScreen(),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  void _handleRecoverySubmission(
    String identifier,
  ) {
    if (identifier.isEmpty) {
      _showMessage(
        'Please enter your email or contact number.',
      );
      return;
    }

    _showMessage(
      'Password recovery backend will be connected next.',
    );
  }

  Future<void> _openForgotPassword() async {
    final result =
        await Navigator.of(context).push<
            ForgotPasswordReturnAction>(
      MaterialPageRoute(
        builder: (_) {
          return ForgotPasswordScreen(
            onRecoverySubmitted: (
              identifier,
            ) {
              _handleRecoverySubmission(
                identifier,
              );
            },
          );
        },
      ),
    );

    if (!mounted) {
      return;
    }

    if (result ==
        ForgotPasswordReturnAction.register) {
      _setAuthView(
        LandingHeroView.register,
      );
      return;
    }

    _setAuthView(
      LandingHeroView.login,
    );
  }
}