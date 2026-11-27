import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'app_colors.dart';

/// Supabase-dashboard inspired dark theme: flat surfaces, 1px borders,
/// 6px radii, 14px body text and a green accent.
abstract final class AppTheme {
  static const double radius = 6;

  static ThemeData get dark {
    final baseTextTheme = GoogleFonts.interTextTheme(
      ThemeData.dark().textTheme,
    ).apply(
      bodyColor: AppColors.textPrimary,
      displayColor: AppColors.textPrimary,
    );

    final textTheme = baseTextTheme.copyWith(
      titleLarge: baseTextTheme.titleLarge?.copyWith(
        fontSize: 20,
        fontWeight: FontWeight.w600,
      ),
      titleMedium: baseTextTheme.titleMedium?.copyWith(
        fontSize: 16,
        fontWeight: FontWeight.w600,
      ),
      titleSmall: baseTextTheme.titleSmall?.copyWith(
        fontSize: 14,
        fontWeight: FontWeight.w600,
      ),
      bodyLarge: baseTextTheme.bodyLarge?.copyWith(fontSize: 14),
      bodyMedium: baseTextTheme.bodyMedium?.copyWith(fontSize: 14),
      bodySmall: baseTextTheme.bodySmall?.copyWith(
        fontSize: 12,
        color: AppColors.textSecondary,
      ),
      labelLarge: baseTextTheme.labelLarge?.copyWith(
        fontSize: 14,
        fontWeight: FontWeight.w500,
      ),
      labelMedium: baseTextTheme.labelMedium?.copyWith(
        fontSize: 13,
        fontWeight: FontWeight.w500,
        color: AppColors.textSecondary,
      ),
      labelSmall: baseTextTheme.labelSmall?.copyWith(
        fontSize: 12,
        color: AppColors.textMuted,
      ),
    );

    const colorScheme = ColorScheme.dark(
      primary: AppColors.brand,
      onPrimary: Color(0xFF0B1F16),
      secondary: AppColors.brand,
      onSecondary: Color(0xFF0B1F16),
      surface: AppColors.background,
      onSurface: AppColors.textPrimary,
      error: AppColors.destructive,
      onError: Colors.white,
      outline: AppColors.borderStrong,
      outlineVariant: AppColors.border,
    );

    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: AppColors.background,
      canvasColor: AppColors.background,
      textTheme: textTheme,
      splashFactory: NoSplash.splashFactory,
      highlightColor: AppColors.surfaceHover.withValues(alpha: 0.6),
      hoverColor: AppColors.surfaceHover,
      dividerTheme: const DividerThemeData(
        color: AppColors.border,
        thickness: 1,
        space: 1,
      ),
      iconTheme: const IconThemeData(color: AppColors.textSecondary, size: 20),
      appBarTheme: AppBarTheme(
        backgroundColor: AppColors.background,
        foregroundColor: AppColors.textPrimary,
        elevation: 0,
        scrolledUnderElevation: 0,
        surfaceTintColor: Colors.transparent,
        centerTitle: false,
        titleTextStyle: textTheme.titleMedium,
        shape: const Border(bottom: BorderSide(color: AppColors.border)),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.control,
        isDense: true,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 12,
          vertical: 12,
        ),
        hintStyle: textTheme.bodyMedium?.copyWith(color: AppColors.textMuted),
        helperStyle: textTheme.bodySmall?.copyWith(color: AppColors.textMuted),
        errorStyle: textTheme.bodySmall?.copyWith(color: AppColors.destructive),
        prefixIconColor: AppColors.textMuted,
        suffixIconColor: AppColors.textMuted,
        border: _inputBorder(AppColors.borderStrong),
        enabledBorder: _inputBorder(AppColors.borderStrong),
        disabledBorder: _inputBorder(AppColors.border),
        focusedBorder: _inputBorder(AppColors.brand),
        errorBorder: _inputBorder(AppColors.destructive),
        focusedErrorBorder: _inputBorder(AppColors.destructive),
      ),
      textSelectionTheme: const TextSelectionThemeData(
        cursorColor: AppColors.brand,
        selectionColor: Color(0x553ECF8E),
        selectionHandleColor: AppColors.brand,
      ),
      progressIndicatorTheme: const ProgressIndicatorThemeData(
        color: AppColors.brand,
      ),
      snackBarTheme: SnackBarThemeData(
        backgroundColor: AppColors.surfaceHover,
        contentTextStyle: textTheme.bodyMedium,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(radius),
          side: const BorderSide(color: AppColors.borderStrong),
        ),
      ),
    );
  }

  static OutlineInputBorder _inputBorder(Color color) {
    return OutlineInputBorder(
      borderRadius: BorderRadius.circular(radius),
      borderSide: BorderSide(color: color),
    );
  }
}
