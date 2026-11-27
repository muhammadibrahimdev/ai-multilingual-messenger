import 'dart:ui' show TextDirection;

import 'package:ai_multilingual_messenger/core/constants/app_language.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('AppLanguage', () {
    test('has the eight supported languages with unique two-letter codes', () {
      final codes = AppLanguage.values.map((l) => l.code).toList();

      expect(codes, ['en', 'ur', 'ar', 'hi', 'fr', 'es', 'pa', 'sd']);
      expect(codes.toSet().length, codes.length);
    });

    test('fromCode finds a language and falls back to English', () {
      expect(AppLanguage.fromCode('ar'), AppLanguage.arabic);
      expect(AppLanguage.fromCode('sd'), AppLanguage.sindhi);
      expect(AppLanguage.fromCode('xx'), AppLanguage.english);
      expect(AppLanguage.fromCode(null), AppLanguage.english);
    });

    test('Arabic-script languages read right to left', () {
      for (final language in [
        AppLanguage.urdu,
        AppLanguage.arabic,
        AppLanguage.sindhi,
      ]) {
        expect(language.textDirection, TextDirection.rtl);
      }
      expect(AppLanguage.hindi.textDirection, TextDirection.ltr);
      expect(AppLanguage.french.textDirection, TextDirection.ltr);
    });

    test('only Punjabi and Sindhi are marked beta', () {
      final beta = AppLanguage.values.where((l) => l.isBeta).toSet();

      expect(beta, {AppLanguage.punjabi, AppLanguage.sindhi});
    });
  });
}
