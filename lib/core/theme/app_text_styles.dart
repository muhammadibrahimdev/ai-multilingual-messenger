import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../constants/app_language.dart';
import 'app_colors.dart';

/// Text styles that depend on content language rather than on the theme.
///
/// Each script gets a Noto font. Urdu uses Nastaliq, which needs a taller
/// line height than other scripts to avoid clipping.
abstract final class AppTextStyles {
  /// Style for chat message text.
  static TextStyle message({
    required AppLanguage? language,
    Color color = AppColors.textPrimary,
    double fontSize = 15,
  }) {
    return switch (language) {
      AppLanguage.urdu => GoogleFonts.notoNastaliqUrdu(
        fontSize: fontSize + 1,
        height: 1.9,
        color: color,
      ),
      AppLanguage.arabic || AppLanguage.sindhi => GoogleFonts.notoNaskhArabic(
        fontSize: fontSize + 1,
        height: 1.7,
        color: color,
      ),
      AppLanguage.hindi => GoogleFonts.notoSansDevanagari(
        fontSize: fontSize,
        height: 1.5,
        color: color,
      ),
      AppLanguage.punjabi => GoogleFonts.notoSansGurmukhi(
        fontSize: fontSize,
        height: 1.5,
        color: color,
      ),
      _ => GoogleFonts.inter(fontSize: fontSize, height: 1.4, color: color),
    };
  }

  /// Compact style for a language's own name, as shown in the language picker.
  static TextStyle nativeLabel(AppLanguage language, {required Color color}) {
    return switch (language) {
      AppLanguage.urdu => GoogleFonts.notoNastaliqUrdu(
        fontSize: 15,
        color: color,
      ),
      AppLanguage.arabic || AppLanguage.sindhi => GoogleFonts.notoNaskhArabic(
        fontSize: 15,
        color: color,
      ),
      AppLanguage.hindi => GoogleFonts.notoSansDevanagari(
        fontSize: 14,
        fontWeight: FontWeight.w500,
        color: color,
      ),
      AppLanguage.punjabi => GoogleFonts.notoSansGurmukhi(
        fontSize: 14,
        fontWeight: FontWeight.w500,
        color: color,
      ),
      _ => GoogleFonts.inter(
        fontSize: 14,
        fontWeight: FontWeight.w500,
        color: color,
      ),
    };
  }
}
