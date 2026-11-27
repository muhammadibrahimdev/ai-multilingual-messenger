/// Compile-time configuration.
///
/// Values are injected with `--dart-define-from-file=dart_defines.json`, so no
/// credentials are committed to source control. Only the public (publishable /
/// anon) Supabase key belongs here — never the service-role key or the Groq key.
abstract final class AppConfig {
  static const String supabaseUrl = String.fromEnvironment('SUPABASE_URL');
  static const String supabaseAnonKey = String.fromEnvironment(
    'SUPABASE_ANON_KEY',
  );

  static bool get isConfigured =>
      supabaseUrl.isNotEmpty && supabaseAnonKey.isNotEmpty;
}
