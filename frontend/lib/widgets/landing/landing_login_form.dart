import 'package:flutter/material.dart';

import '../../app/theme.dart';

class LandingLoginForm extends StatefulWidget {
  const LandingLoginForm({
    super.key,
    required this.onLoginPressed,
    required this.onBackPressed,
    required this.onRegisterPressed,
  });

  final void Function(
    String identifier,
    String password,
  ) onLoginPressed;

  final VoidCallback onBackPressed;
  final VoidCallback onRegisterPressed;

  @override
  State<LandingLoginForm> createState() =>
      _LandingLoginFormState();
}

class _LandingLoginFormState
    extends State<LandingLoginForm> {
  final TextEditingController _identifierController =
      TextEditingController();

  final TextEditingController _passwordController =
      TextEditingController();

  bool _obscurePassword = true;

  @override
  void dispose() {
    _identifierController.dispose();
    _passwordController.dispose();

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      height: double.infinity,
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
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              IconButton(
                tooltip: 'Back',
                onPressed: widget.onBackPressed,
                icon: const Icon(
                  Icons.arrow_back_rounded,
                  color: AppColors.textPrimary,
                ),
              ),

              const Spacer(),

              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: AppColors.primaryDark,
                  borderRadius: BorderRadius.circular(
                    AppRadius.medium,
                  ),
                ),
                child: const Icon(
                  Icons.lock_outline_rounded,
                  color: AppColors.primary,
                  size: 23,
                ),
              ),
            ],
          ),

          const SizedBox(height: 22),

          const Text(
            'Login to gUSo',
            style: TextStyle(
              color: AppColors.textPrimary,
              fontSize: 28,
              fontWeight: FontWeight.w800,
            ),
          ),

          const SizedBox(height: 8),

          const Text(
            'Enter your account information to continue.',
            style: TextStyle(
              color: AppColors.textSecondary,
              fontSize: 14,
              height: 1.5,
            ),
          ),

          const SizedBox(height: 30),

          TextField(
            controller: _identifierController,
            keyboardType: TextInputType.emailAddress,
            style: const TextStyle(
              color: AppColors.textPrimary,
            ),
            decoration: const InputDecoration(
              hintText: 'Email or Contact number',
              prefixIcon: Icon(
                Icons.person_outline_rounded,
              ),
            ),
          ),

          const SizedBox(height: 18),

          TextField(
            controller: _passwordController,
            obscureText: _obscurePassword,
            style: const TextStyle(
              color: AppColors.textPrimary,
            ),
            onSubmitted: (_) {
              _submitLogin();
            },
            decoration: InputDecoration(
              hintText: 'Password',
              prefixIcon: const Icon(
                Icons.lock_outline_rounded,
              ),
              suffixIcon: IconButton(
                tooltip: _obscurePassword
                    ? 'Show password'
                    : 'Hide password',
                onPressed: () {
                  setState(() {
                    _obscurePassword =
                        !_obscurePassword;
                  });
                },
                icon: Icon(
                  _obscurePassword
                      ? Icons.visibility_outlined
                      : Icons.visibility_off_outlined,
                ),
              ),
            ),
          ),

          const SizedBox(height: 28),

          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: _submitLogin,
              style: ButtonStyle(
                elevation:
                    const WidgetStatePropertyAll(0),

                backgroundColor:
                    WidgetStateProperty.resolveWith<Color>(
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
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              icon: const Icon(
                Icons.login_rounded,
              ),
              label: const Text(
                'LOGIN',
              ),
            ),
          ),

          const SizedBox(height: 22),

          Center(
            child: Wrap(
              crossAxisAlignment:
                  WrapCrossAlignment.center,
              children: [
                const Text(
                  "Don't have an account? ",
                  style: TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 14,
                  ),
                ),
                TextButton(
                  onPressed:
                      widget.onRegisterPressed,
                  style: TextButton.styleFrom(
                    foregroundColor:
                        AppColors.primary,
                    padding:
                        const EdgeInsets.symmetric(
                      horizontal: 4,
                      vertical: 2,
                    ),
                    minimumSize: Size.zero,
                    tapTargetSize:
                        MaterialTapTargetSize
                            .shrinkWrap,
                  ),
                  child: const Text(
                    'Register',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
          ),

          const Spacer(),

          const Center(
            child: Text(
              'Secure access to the gUSo classification workspace',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: AppColors.textMuted,
                fontSize: 12,
                height: 1.5,
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _submitLogin() {
    final identifier =
        _identifierController.text.trim();

    final password =
        _passwordController.text;

    widget.onLoginPressed(
      identifier,
      password,
    );
  }
}