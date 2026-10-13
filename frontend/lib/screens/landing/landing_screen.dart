import 'package:flutter/material.dart';

import '../../app/theme.dart';
import '../../screens/home/home_screen.dart';
import '../../screens/seaweed_guide/seaweed_guide_screen.dart';

import '../../services/auth_service.dart';

import '../../widgets/landing/landing_about.dart';
import '../../widgets/landing/landing_footer.dart';
import '../../widgets/landing/landing_hero.dart';
import '../../widgets/landing/landing_how_it_works.dart';
import '../../widgets/landing/landing_navbar.dart';
import '../../widgets/landing/landing_seaweed_guide_preview.dart';

class LandingScreen extends StatefulWidget {
  const LandingScreen({super.key});

  @override
  State<LandingScreen> createState() => _LandingScreenState();
}

class _LandingScreenState extends State<LandingScreen> {
  final AuthService _authService = const AuthService();

  static const double _desktopBreakpoint = 1200;
  static const double _mobileBreakpoint = 768;
  static const double _maxContentWidth = 1440;
  static const double _navbarHeight = 92;

  final ScrollController _scrollController = ScrollController();

  final GlobalKey _homeKey = GlobalKey();
  final GlobalKey _aboutKey = GlobalKey();
  final GlobalKey _howItWorksKey = GlobalKey();
  final GlobalKey _seaweedGuideKey = GlobalKey();

  LandingHeroView _authView = LandingHeroView.preview;

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Stack(
          children: [
            Positioned.fill(
              child: SingleChildScrollView(
                controller: _scrollController,
                padding: const EdgeInsets.only(top: _navbarHeight),
                child: Column(
                  children: [
                    KeyedSubtree(
                      key: _homeKey,
                      child: LandingHero(
                        desktopBreakpoint: _desktopBreakpoint,
                        mobileBreakpoint: _mobileBreakpoint,
                        maxContentWidth: _maxContentWidth,

                        onGetStartedPressed: _openRegisterPanel,

                        onExploreGuidePressed: _openSeaweedGuide,

                        authView: _authView,

                        onLoginSubmitted: (identifier, password) {
                          _handleLoginSubmission(identifier, password);
                        },

                        onRegisterSubmitted:
                            (
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

                        onShowLogin: _showLoginPanel,

                        onShowRegister: _showRegisterPanel,

                        onBackToPreview: _showPreviewPanel,
                      ),
                    ),

                    KeyedSubtree(
                      key: _aboutKey,
                      child: const LandingAbout(
                        desktopBreakpoint: _desktopBreakpoint,
                        mobileBreakpoint: _mobileBreakpoint,
                        maxContentWidth: _maxContentWidth,
                      ),
                    ),

                    KeyedSubtree(
                      key: _howItWorksKey,
                      child: const LandingHowItWorks(
                        desktopBreakpoint: _desktopBreakpoint,
                        mobileBreakpoint: _mobileBreakpoint,
                        maxContentWidth: _maxContentWidth,
                      ),
                    ),

                    KeyedSubtree(
                      key: _seaweedGuideKey,
                      child: LandingSeaweedGuidePreview(
                        desktopBreakpoint: _desktopBreakpoint,
                        mobileBreakpoint: _mobileBreakpoint,
                        maxContentWidth: _maxContentWidth,
                        onExploreGuidePressed: _openSeaweedGuide,
                      ),
                    ),

                    LandingFooter(
                      desktopBreakpoint: _desktopBreakpoint,
                      mobileBreakpoint: _mobileBreakpoint,
                      maxContentWidth: _maxContentWidth,

                      onHomePressed: _returnToHome,

                      onAboutPressed: () {
                        _scrollToSection(_aboutKey);
                      },

                      onHowItWorksPressed: () {
                        _scrollToSection(_howItWorksKey);
                      },

                      onSeaweedGuidePressed: () {
                        _scrollToSection(_seaweedGuideKey);
                      },

                      onGetStartedPressed: _openRegisterPanel,
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
                      color: AppColors.disabled.withValues(alpha: 0.55),
                    ),
                  ),
                ),
                child: LandingNavbar(
                  desktopBreakpoint: _desktopBreakpoint,
                  mobileBreakpoint: _mobileBreakpoint,
                  maxContentWidth: _maxContentWidth,

                  onHomePressed: _returnToHome,

                  onAboutPressed: () {
                    _scrollToSection(_aboutKey);
                  },

                  onHowItWorksPressed: () {
                    _scrollToSection(_howItWorksKey);
                  },

                  onSeaweedGuidePressed: () {
                    _scrollToSection(_seaweedGuideKey);
                  },

                  onLoginPressed: _openLoginPanel,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _openLoginPanel() {
    _setAuthView(LandingHeroView.login);
  }

  void _openRegisterPanel() {
    _setAuthView(LandingHeroView.register);
  }

  void _showLoginPanel() {
    _setAuthView(LandingHeroView.login);
  }

  void _showRegisterPanel() {
    _setAuthView(LandingHeroView.register);
  }

  void _showPreviewPanel() {
    if (_authView == LandingHeroView.preview) {
      return;
    }

    setState(() {
      _authView = LandingHeroView.preview;
    });
  }

  void _setAuthView(LandingHeroView view) {
    if (_authView != view) {
      setState(() {
        _authView = view;
      });
    }

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) {
        return;
      }

      _scrollToSection(_homeKey);
    });
  }

  void _returnToHome() {
    if (_authView != LandingHeroView.preview) {
      setState(() {
        _authView = LandingHeroView.preview;
      });
    }

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) {
        return;
      }

      _scrollToSection(_homeKey);
    });
  }

  Future<void> _handleLoginSubmission(
    String identifier,
    String password,
  ) async {
    final cleanIdentifier = identifier.trim();

    // =============================================
    // FRONTEND VALIDATION
    // =============================================

    if (cleanIdentifier.isEmpty) {
      _showMessage('Please enter your email or contact number.');
      return;
    }

    if (password.isEmpty) {
      _showMessage('Please enter your password.');
      return;
    }

    // =============================================
    // SEND LOGIN TO FASTAPI
    // =============================================

    try {
      final response = await _authService.login(
        identifier: cleanIdentifier,
        password: password,
      );

      if (!mounted) {
        return;
      }

      final message = response['message']?.toString() ?? 'Login successful.';

      _showMessage(message);

      // =============================================
      // OPEN MAIN APPLICATION
      // =============================================

      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (context) => const HomeScreen()),
      );
    } catch (e) {
      if (!mounted) {
        return;
      }

      final errorMessage = e.toString().replaceFirst('Exception: ', '');

      _showMessage(errorMessage);
    }
  }

  Future<void> _handleRegisterSubmission(
    String firstName,
    String lastName,
    String email,
    String contactNumber,
    String password,
    String confirmPassword,
  ) async {
    final cleanFirstName = firstName.trim();
    final cleanLastName = lastName.trim();
    final cleanEmail = email.trim();
    final cleanContactNumber = contactNumber.trim();

    // =============================================
    // FRONTEND VALIDATION
    // =============================================

    if (cleanFirstName.isEmpty) {
      _showMessage('Please enter your first name.');
      return;
    }

    if (cleanLastName.isEmpty) {
      _showMessage('Please enter your last name.');
      return;
    }

    // if (cleanEmail.isEmpty) {
    //   _showMessage('Please enter your email address.');
    //   return;
    // }

    if (cleanEmail.isNotEmpty && !_looksLikeEmail(cleanEmail)) {
      _showMessage('Please enter a valid email address or leave it blank.');
      return;
    }

    if (cleanContactNumber.isEmpty) {
      _showMessage('Please enter your contact number.');
      return;
    }

    if (password.isEmpty) {
      _showMessage('Please create a password.');
      return;
    }

    if (password.length < 8) {
      _showMessage('Password must contain at least 8 characters.');
      return;
    }

    if (confirmPassword.isEmpty) {
      _showMessage('Please confirm your password.');
      return;
    }

    if (password != confirmPassword) {
      _showMessage('Passwords do not match.');
      return;
    }

    // =============================================
    // SEND REGISTRATION TO FASTAPI
    // =============================================

    try {
      final response = await _authService.register(
        firstName: cleanFirstName,
        lastName: cleanLastName,
        email: cleanEmail,
        contactNumber: cleanContactNumber,
        password: password,
        confirmPassword: confirmPassword,
      );

      if (!mounted) {
        return;
      }

      final message =
          response['message']?.toString() ?? 'Registration successful.';

      _showMessage(message);

      // Move to Login panel after registration.
      _showLoginPanel();
    } catch (e) {
      if (!mounted) {
        return;
      }

      final errorMessage = e.toString().replaceFirst('Exception: ', '');

      _showMessage(errorMessage);
    }
  }

  bool _looksLikeEmail(String email) {
    final emailPattern = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$');

    return emailPattern.hasMatch(email);
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(message)));
  }

  Future<void> _scrollToSection(GlobalKey key) async {
    final sectionContext = key.currentContext;

    if (sectionContext == null || !_scrollController.hasClients) {
      return;
    }

    final renderObject = sectionContext.findRenderObject();

    if (renderObject is! RenderBox) {
      return;
    }

    final sectionPosition = renderObject.localToGlobal(Offset.zero).dy;

    final targetOffset =
        _scrollController.offset + sectionPosition - _navbarHeight - 12;

    final safeOffset = targetOffset.clamp(
      0.0,
      _scrollController.position.maxScrollExtent,
    );

    await _scrollController.animateTo(
      safeOffset,
      duration: const Duration(milliseconds: 550),
      curve: Curves.easeInOutCubic,
    );
  }

  void _openSeaweedGuide() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (routeContext) {
          return Scaffold(
            backgroundColor: AppColors.background,
            body: SafeArea(
              child: Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(28, 20, 28, 0),
                    child: Align(
                      alignment: Alignment.centerLeft,
                      child: TextButton.icon(
                        onPressed: () {
                          Navigator.of(routeContext).pop();
                        },
                        icon: const Icon(Icons.arrow_back_rounded),
                        label: const Text('Back to Landing Page'),
                      ),
                    ),
                  ),
                  const Expanded(child: SeaweedGuideScreen()),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
