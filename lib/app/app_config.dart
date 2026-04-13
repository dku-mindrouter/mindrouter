class AppConfig {
  const AppConfig({
    required this.supabaseUrl,
    required this.supabaseAnonKey,
    required this.defaultTimezone,
  });

  factory AppConfig.fromEnvironment() {
    return const AppConfig(
      supabaseUrl: String.fromEnvironment('SUPABASE_URL'),
      supabaseAnonKey: String.fromEnvironment('SUPABASE_ANON_KEY'),
      defaultTimezone: String.fromEnvironment(
        'APP_DEFAULT_TIMEZONE',
        defaultValue: 'Asia/Seoul',
      ),
    );
  }

  final String supabaseUrl;
  final String supabaseAnonKey;
  final String defaultTimezone;

  bool get hasSupabaseConfig =>
      supabaseUrl.trim().isNotEmpty && supabaseAnonKey.trim().isNotEmpty;
}
