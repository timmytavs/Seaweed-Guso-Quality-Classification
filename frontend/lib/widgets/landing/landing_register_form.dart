import 'package:flutter/material.dart';

import '../../app/theme.dart';

class LandingRegisterForm extends StatefulWidget {
  const LandingRegisterForm({
    super.key,
    required this.onRegisterPressed,
    required this.onBackPressed,
    required this.onLoginPressed,
  });

  final void Function(
    String firstName,
    String lastName,
    String email,
    String contactNumber,
    String password,
    String confirmPassword,
  ) onRegisterPressed;

  final VoidCallback onBackPressed;
  final VoidCallback onLoginPressed;

  @override
  State<LandingRegisterForm> createState() =>
      _LandingRegisterFormState();
}

class _LandingRegisterFormState
    extends State<LandingRegisterForm> {
  final TextEditingController _firstNameController =
      TextEditingController();

  final TextEditingController _lastNameController =
      TextEditingController();

  final TextEditingController _emailController =
      TextEditingController();

  final TextEditingController _contactNumberController =
      TextEditingController();

  final TextEditingController _passwordController =
      TextEditingController();

  final TextEditingController _confirmPasswordController =
      TextEditingController();

  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;

  @override
  void dispose() {
    _firstNameController.dispose();
    _lastNameController.dispose();
    _emailController.dispose();
    _contactNumberController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      height: double.infinity,
      padding: const EdgeInsets.all(28),
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
      child: LayoutBuilder(
        builder: (context, constraints) {
          return SingleChildScrollView(
            child: ConstrainedBox(
              constraints: BoxConstraints(
                minHeight: constraints.maxHeight,
              ),
              child: IntrinsicHeight(
                child: Column(
                  crossAxisAlignment:
                      CrossAxisAlignment.start,
                  children: [
                    _buildHeader(),

                    const SizedBox(height: 20),

                    const Text(
                      'Create your gUSo account',
                      style: TextStyle(
                        color: AppColors.textPrimary,
                        fontSize: 26,
                        fontWeight: FontWeight.w800,
                      ),
                    ),

                    const SizedBox(height: 8),

                    const Text(
                      'Fill in your account information to get started.',
                      style: TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 14,
                        height: 1.5,
                      ),
                    ),

                    const SizedBox(height: 24),

                    _buildNameFields(
                      constraints.maxWidth,
                    ),

                    const SizedBox(height: 16),

                    TextField(
                      controller: _emailController,
                      keyboardType:
                          TextInputType.emailAddress,
                      style: const TextStyle(
                        color: AppColors.textPrimary,
                      ),
                      decoration:
                          const InputDecoration(
                        hintText: 'Email (Optional)',
                        prefixIcon: Icon(
                          Icons.email_outlined,
                        ),
                      ),
                    ),

                    const SizedBox(height: 16),

                    TextField(
                      controller:
                          _contactNumberController,
                      keyboardType:
                          TextInputType.phone,
                      style: const TextStyle(
                        color: AppColors.textPrimary,
                      ),
                      decoration:
                          const InputDecoration(
                        hintText: 'Contact number',
                        prefixIcon: Icon(
                          Icons.phone_outlined,
                        ),
                      ),
                    ),

                    const SizedBox(height: 16),

                    TextField(
                      controller:
                          _passwordController,
                      obscureText:
                          _obscurePassword,
                      style: const TextStyle(
                        color: AppColors.textPrimary,
                      ),
                      decoration: InputDecoration(
                        hintText: 'Create password',
                        prefixIcon: const Icon(
                          Icons.lock_outline_rounded,
                        ),
                        suffixIcon: IconButton(
                          tooltip:
                              _obscurePassword
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
                                ? Icons
                                    .visibility_outlined
                                : Icons
                                    .visibility_off_outlined,
                          ),
                        ),
                      ),
                    ),

                    const SizedBox(height: 16),

                    TextField(
                      controller:
                          _confirmPasswordController,
                      obscureText:
                          _obscureConfirmPassword,
                      style: const TextStyle(
                        color: AppColors.textPrimary,
                      ),
                      onSubmitted: (_) {
                        _submitRegistration();
                      },
                      decoration: InputDecoration(
                        hintText:
                            'Confirm password',
                        prefixIcon: const Icon(
                          Icons
                              .verified_user_outlined,
                        ),
                        suffixIcon: IconButton(
                          tooltip:
                              _obscureConfirmPassword
                                  ? 'Show password'
                                  : 'Hide password',
                          onPressed: () {
                            setState(() {
                              _obscureConfirmPassword =
                                  !_obscureConfirmPassword;
                            });
                          },
                          icon: Icon(
                            _obscureConfirmPassword
                                ? Icons
                                    .visibility_outlined
                                : Icons
                                    .visibility_off_outlined,
                          ),
                        ),
                      ),
                    ),

                    const SizedBox(height: 24),

                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed:
                            _submitRegistration,
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
                              .person_add_alt_1_rounded,
                        ),
                        label: const Text(
                          'CREATE ACCOUNT',
                        ),
                      ),
                    ),

                    const SizedBox(height: 18),

                    Center(
                      child: Wrap(
                        crossAxisAlignment:
                            WrapCrossAlignment.center,
                        children: [
                          const Text(
                            'Already have an account? ',
                            style: TextStyle(
                              color: AppColors
                                  .textSecondary,
                              fontSize: 14,
                            ),
                          ),
                          TextButton(
                            onPressed:
                                widget.onLoginPressed,
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

                    const SizedBox(height: 12),

                    const Spacer(),

                    const Center(
                      child: Text(
                        'Create an account to access the gUSo classification workspace.',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color:
                              AppColors.textMuted,
                          fontSize: 12,
                          height: 1.5,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildHeader() {
    return Row(
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
            Icons.person_add_alt_1_outlined,
            color: AppColors.primary,
            size: 23,
          ),
        ),
      ],
    );
  }

  Widget _buildNameFields(
    double availableWidth,
  ) {
    final stackNames = availableWidth < 500;

    final firstNameField = TextField(
      controller: _firstNameController,
      textCapitalization:
          TextCapitalization.words,
      style: const TextStyle(
        color: AppColors.textPrimary,
      ),
      decoration: const InputDecoration(
        hintText: 'First name',
        prefixIcon: Icon(
          Icons.person_outline_rounded,
        ),
      ),
    );

    final lastNameField = TextField(
      controller: _lastNameController,
      textCapitalization:
          TextCapitalization.words,
      style: const TextStyle(
        color: AppColors.textPrimary,
      ),
      decoration: const InputDecoration(
        hintText: 'Last name',
        prefixIcon: Icon(
          Icons.person_outline_rounded,
        ),
      ),
    );

    if (stackNames) {
      return Column(
        children: [
          firstNameField,
          const SizedBox(height: 16),
          lastNameField,
        ],
      );
    }

    return Row(
      children: [
        Expanded(
          child: firstNameField,
        ),
        const SizedBox(width: 14),
        Expanded(
          child: lastNameField,
        ),
      ],
    );
  }

  void _submitRegistration() {
    final firstName =
        _firstNameController.text.trim();

    final lastName =
        _lastNameController.text.trim();

    final email =
        _emailController.text.trim();

    final contactNumber =
        _contactNumberController.text.trim();

    final password =
        _passwordController.text;

    final confirmPassword =
        _confirmPasswordController.text;

    widget.onRegisterPressed(
      firstName,
      lastName,
      email,
      contactNumber,
      password,
      confirmPassword,
    );
  }
}