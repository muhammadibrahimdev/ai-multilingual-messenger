import 'dart:ui' show TextDirection;

/// Languages supported by the app. The [code] matches the values allowed by
/// the `preferred_language` / `source_lang` / `target_lang` database columns
/// and is also the language hint sent to Whisper.
///
/// [isBeta] marks languages where translation and speech recognition are
/// noticeably less accurate.
enum AppLanguage {
  english(code: 'en', name: 'English', nativeName: 'English', isRtl: false),
  urdu(code: 'ur', name: 'Urdu', nativeName: 'اردو', isRtl: true),
  arabic(code: 'ar', name: 'Arabic', nativeName: 'العربية', isRtl: true),
  hindi(code: 'hi', name: 'Hindi', nativeName: 'हिन्दी', isRtl: false),
  french(code: 'fr', name: 'French', nativeName: 'Français', isRtl: false),
  spanish(code: 'es', name: 'Spanish', nativeName: 'Español', isRtl: false),
  punjabi(
    code: 'pa',
    name: 'Punjabi',
    nativeName: 'ਪੰਜਾਬੀ',
    isRtl: false,
    isBeta: true,
  ),
  sindhi(
    code: 'sd',
    name: 'Sindhi',
    nativeName: 'سنڌي',
    isRtl: true,
    isBeta: true,
  );

  const AppLanguage({
    required this.code,
    required this.name,
    required this.nativeName,
    required this.isRtl,
    this.isBeta = false,
  });

  final String code;
  final String name;
  final String nativeName;
  final bool isRtl;
  final bool isBeta;

  TextDirection get textDirection =>
      isRtl ? TextDirection.rtl : TextDirection.ltr;

  static AppLanguage fromCode(String? code) {
    return AppLanguage.values.firstWhere(
      (language) => language.code == code,
      orElse: () => AppLanguage.english,
    );
  }
}
