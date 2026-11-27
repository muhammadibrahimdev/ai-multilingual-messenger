import 'package:flutter/material.dart';

/// Colour tokens modelled on the Supabase dashboard (dark theme).
abstract final class AppColors {
  // Surfaces
  static const Color background = Color(0xFF1C1C1C);
  static const Color backgroundAlt = Color(0xFF171717);
  static const Color surface = Color(0xFF232323);
  static const Color surfaceHover = Color(0xFF2A2A2A);
  static const Color control = Color(0xFF1F1F1F);

  // Borders
  static const Color border = Color(0xFF2E2E2E);
  static const Color borderStrong = Color(0xFF363636);
  static const Color borderStronger = Color(0xFF454545);

  // Text
  static const Color textPrimary = Color(0xFFEDEDED);
  static const Color textSecondary = Color(0xFFA0A0A0);
  static const Color textMuted = Color(0xFF707070);

  // Brand
  static const Color brand = Color(0xFF3ECF8E);
  static const Color brandButton = Color(0xFF006239);
  static const Color brandButtonBorder = Color(0xFF1F9D68);
  static const Color brandSubtle = Color(0xFF10261C);
  static const Color brandSubtleBorder = Color(0xFF1B4A34);

  // Destructive
  static const Color destructive = Color(0xFFE5484D);
  static const Color destructiveSubtle = Color(0xFF2D1618);
  static const Color destructiveBorder = Color(0xFF5E2428);
}
