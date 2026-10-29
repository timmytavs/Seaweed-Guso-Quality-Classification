import 'package:flutter/material.dart';

import '../../app/theme.dart';

enum ForgotPasswordReturnAction {
  login,
  register,
}

class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({
    super.key,
    required this.onRecoverySubmitted,
  });

  final void Function(
    String identifier,
  ) onRecoverySubmitted;

  @override
  State<ForgotPasswordScreen> createState() =>
      _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState
    extends State<ForgotPasswordScreen> {
  final TextEditingController _identifierController =
      TextEditingController();

  @override
  void dispose() {
    _identifierController.dispose();
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
              Color(0xFF0B2D0D),
              Color(0xFF001000),
            ],
            stops: [
              0.0,
              0.48,
              1.0,
            ],
          ),
        ),
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(
              horizontal: 20,
              vertical: 32,
            ),
            child: ConstrainedBox(
              constraints: const BoxConstraints(
                maxWidth: 520,
              ),
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.all(32),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(
                    AppRadius.extraLarge,
                  ),
                  border: Border.all(
                    color: AppColors.borderPrimary,
                    width: 1.5,
                  ),
                ),
                child: Column(
                  crossAxisAlignment:
                      CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        IconButton(
                          tooltip: 'Back',
                          onPressed: () {
                            Navigator.of(context).pop(
                              ForgotPasswordReturnAction
                                  .login,
                            );
                          },
                          icon: const Icon(
                            Icons.arrow_back_rounded,
                            color:
                                AppColors.textPrimary,
                          ),
                        ),

                        const Spacer(),

                        Container(
                          width: 44,
                          height: 44,
                          decoration: BoxDecoration(
                            color:
                                AppColors.primaryDark,
                            borderRadius:
                                BorderRadius.circular(
                              AppRadius.medium,
                            ),
                          ),
                          child: const Icon(
                            Icons
                                .lock_reset_rounded,
                            color:
                                AppColors.primary,
                            size: 24,
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 26),

                    const Text(
                      'Forgot Password?',
                      style: TextStyle(
                        color:
                            AppColors.textPrimary,
                        fontSize: 30,
                        fontWeight:
                            FontWeight.w800,
                      ),
                    ),

                    const SizedBox(height: 10),

                    const Text(
                      'Enter the email or contact number associated '
                      'with your gUSo account. We will use it to start '
                      'the account recovery process.',
                      style: TextStyle(
                        color:
                            AppColors.textSecondary,
                        fontSize: 15,
                        height: 1.6,
                      ),
                    ),

                    const SizedBox(height: 30),

                    TextField(
                      controller:
                          _identifierController,
                      keyboardType:
                          TextInputType.emailAddress,
                      style: const TextStyle(
                        color:
                            AppColors.textPrimary,
                      ),
                      onSubmitted: (_) {
                        _submitRecovery();
                      },
                      decoration:
                          const InputDecoration(
                        hintText:
                            'Email or Contact number',
                        prefixIcon: Icon(
                          Icons
                              .person_search_outlined,
                        ),
                      ),
                    ),

                    const SizedBox(height: 24),

                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed:
                            _submitRecovery,
                        style: ButtonStyle(
                          elevation:
                              const WidgetStatePropertyAll(
                            0,
                          ),
                          backgroundColor:
                              WidgetStateProperty
                                  .resolveWith<Color>(
                            (states) {
                              if (states.contains(
                                WidgetState.hovered,
                              )) {
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
                              const WidgetStatePropertyAll(
                            EdgeInsets.symmetric(
                              horizontal: 28,
                              vertical: 16,
                            ),
                          ),
                          shape:
                              WidgetStatePropertyAll(
                            RoundedRectangleBorder(
                              borderRadius:
                                  BorderRadius.circular(
                                AppRadius.medium,
                              ),
                            ),
                          ),
                          textStyle:
                              const WidgetStatePropertyAll(
                            TextStyle(
                              fontSize: 15,
                              fontWeight:
                                  FontWeight.bold,
                            ),
                          ),
                        ),
                        icon: const Icon(
                          Icons
                              .send_outlined,
                        ),
                        label: const Text(
                          'SEND RECOVERY CODE',
                        ),
                      ),
                    ),

                    const SizedBox(height: 28),

                    Center(
                      child: Wrap(
                        alignment:
                            WrapAlignment.center,
                        crossAxisAlignment:
                            WrapCrossAlignment.center,
                        children: [
                          const Text(
                            'Remember your password? ',
                            style: TextStyle(
                              color: AppColors
                                  .textSecondary,
                              fontSize: 14,
                            ),
                          ),
                          TextButton(
                            onPressed: () {
                              Navigator.of(context).pop(
                                ForgotPasswordReturnAction
                                    .login,
                              );
                            },
                            style:
                                TextButton.styleFrom(
                              foregroundColor:
                                  AppColors.primary,
                              padding:
                                  const EdgeInsets
                                      .symmetric(
                                horizontal: 4,
                                vertical: 2,
                              ),
                              minimumSize:
                                  Size.zero,
                              tapTargetSize:
                                  MaterialTapTargetSize
                                      .shrinkWrap,
                            ),
                            child: const Text(
                              'Login',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight:
                                    FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 8),

                    Center(
                      child: Wrap(
                        alignment:
                            WrapAlignment.center,
                        crossAxisAlignment:
                            WrapCrossAlignment.center,
                        children: [
                          const Text(
                            "Don't have an account? ",
                            style: TextStyle(
                              color: AppColors
                                  .textSecondary,
                              fontSize: 14,
                            ),
                          ),
                          TextButton(
                            onPressed: () {
                              Navigator.of(context).pop(
                                ForgotPasswordReturnAction
                                    .register,
                              );
                            },
                            style:
                                TextButton.styleFrom(
                              foregroundColor:
                                  AppColors.primary,
                              padding:
                                  const EdgeInsets
                                      .symmetric(
                                horizontal: 4,
                                vertical: 2,
                              ),
                              minimumSize:
                                  Size.zero,
                              tapTargetSize:
                                  MaterialTapTargetSize
                                      .shrinkWrap,
                            ),
                            child: const Text(
                              'Register',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight:
                                    FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  void _submitRecovery() {
    final identifier =
        _identifierController.text.trim();

    if (identifier.isEmpty) {
      ScaffoldMessenger.of(context)
          .showSnackBar(
        const SnackBar(
          content: Text(
            'Please enter your email or contact number.',
          ),
        ),
      );

      return;
    }

    widget.onRecoverySubmitted(
      identifier,
    );
  }
}