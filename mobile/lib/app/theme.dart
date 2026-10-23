import 'package:flutter/material.dart';

class AppColors {
  static const Color background = Color(0xFF001000);

  static const Color surface = Color(0xFF0E2204);
  static const Color surfaceDark = Color(0xFF081504);

  static const Color primary = Color(0xFF7BDF50);
  static const Color primaryDark = Color(0xFF124900);

  static const Color textPrimary = Colors.white;
  static const Color textSecondary = Color(0xFFBFC7BC);
  static const Color textMuted = Color(0xFF7B8378);

  static const Color borderLight = Color(0xFF4B5548);
  static const Color borderPrimary = Color(0xFF7BDF50);

  static const Color success = Color(0xFF56C271);
  static const Color warning = Color(0xFFF2C94C);
  static const Color error = Color(0xFFEB5757);

  static const Color disabled = Color(0xFF4B5548);
}

class AppSpacing {
  static const double xs = 4;
  static const double sm = 8;
  static const double md = 16;
  static const double lg = 24;
  static const double xl = 32;
}

class AppRadius {
  static const double small = 8;
  static const double medium = 12;
  static const double large = 18;
  static const double extraLarge = 24;
}

class AppTheme {
  static ThemeData get darkTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,

      scaffoldBackgroundColor: AppColors.background,

      colorScheme: const ColorScheme.dark(
        primary: AppColors.primary,
        secondary: AppColors.primary,
        surface: AppColors.surface,
        error: AppColors.error,
      ),

      appBarTheme: const AppBarTheme(
        backgroundColor: AppColors.background,
        foregroundColor: AppColors.textPrimary,
        elevation: 0,
        centerTitle: false,
      ),

      textTheme: const TextTheme(
        headlineLarge: TextStyle(
          color: AppColors.textPrimary,
          fontSize: 28,
          fontWeight: FontWeight.bold,
        ),
        headlineMedium: TextStyle(
          color: AppColors.textPrimary,
          fontSize: 24,
          fontWeight: FontWeight.bold,
        ),
        titleLarge: TextStyle(
          color: AppColors.textPrimary,
          fontSize: 20,
          fontWeight: FontWeight.w600,
        ),
        titleMedium: TextStyle(
          color: AppColors.textPrimary,
          fontSize: 16,
          fontWeight: FontWeight.w600,
        ),
        bodyLarge: TextStyle(
          color: AppColors.textSecondary,
          fontSize: 16,
          height: 1.5,
        ),
        bodyMedium: TextStyle(
          color: AppColors.textSecondary,
          fontSize: 14,
          height: 1.5,
        ),
        bodySmall: TextStyle(
          color: AppColors.textMuted,
          fontSize: 12,
        ),
      ),

      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.surfaceDark,
        hintStyle: const TextStyle(
          color: AppColors.textMuted,
        ),
        labelStyle: const TextStyle(
          color: AppColors.textSecondary,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(
            AppRadius.medium,
          ),
          borderSide: const BorderSide(
            color: AppColors.borderLight,
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(
            AppRadius.medium,
          ),
          borderSide: const BorderSide(
            color: AppColors.primary,
            width: 1.5,
          ),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(
            AppRadius.medium,
          ),
          borderSide: const BorderSide(
            color: AppColors.error,
          ),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(
            AppRadius.medium,
          ),
          borderSide: const BorderSide(
            color: AppColors.error,
            width: 1.5,
          ),
        ),
      ),

      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primary,
          foregroundColor: Colors.black,
          padding: const EdgeInsets.symmetric(
            horizontal: 20,
            vertical: 14,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(
              AppRadius.medium,
            ),
          ),
          textStyle: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),

      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.textPrimary,
          side: const BorderSide(
            color: AppColors.borderLight,
          ),
          padding: const EdgeInsets.symmetric(
            horizontal: 20,
            vertical: 14,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(
              AppRadius.medium,
            ),
          ),
          textStyle: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),

      dividerTheme: const DividerThemeData(
        color: AppColors.disabled,
        thickness: 1,
      ),

      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: AppColors.surfaceDark,
        indicatorColor: AppColors.primaryDark,
        labelTextStyle:
            WidgetStateProperty.resolveWith<TextStyle>(
          (states) {
            final isSelected =
                states.contains(WidgetState.selected);

            return TextStyle(
              color: isSelected
                  ? AppColors.primary
                  : AppColors.textMuted,
              fontSize: 12,
              fontWeight: isSelected
                  ? FontWeight.w600
                  : FontWeight.w500,
            );
          },
        ),
        iconTheme:
            WidgetStateProperty.resolveWith<IconThemeData>(
          (states) {
            final isSelected =
                states.contains(WidgetState.selected);

            return IconThemeData(
              color: isSelected
                  ? AppColors.primary
                  : AppColors.textMuted,
            );
          },
        ),
      ),
    );
  }
}