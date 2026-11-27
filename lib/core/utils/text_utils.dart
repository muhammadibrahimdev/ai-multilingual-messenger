import 'dart:ui' show TextDirection;

import '../constants/app_language.dart';

abstract final class TextUtils {
  static final RegExp _arabicScript = RegExp(r'[؀-ۿݐ-ݿ]');

  static bool containsArabicScript(String text) => _arabicScript.hasMatch(text);

  /// Reading direction for [text]. A known [language] wins; otherwise the
  /// script of the text decides.
  static TextDirection directionFor(String text, {AppLanguage? language}) {
    if (language != null) return language.textDirection;
    return containsArabicScript(text) ? TextDirection.rtl : TextDirection.ltr;
  }

  /// Best-effort language for [text] when the stored language is unknown.
  static AppLanguage? resolveLanguage(String text, AppLanguage? language) {
    if (language != null) return language;
    return containsArabicScript(text) ? AppLanguage.urdu : null;
  }
}
