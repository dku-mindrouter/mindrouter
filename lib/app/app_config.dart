class AppConfig {
  static const String _defaultSupabaseUrl =
      'https://jgyjbohdactgcavpoogb.supabase.co';
  static const String _defaultSupabaseAnonKey =
      'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImpneWpib2hkYWN0Z2NhdnBvb2diIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NzU3MTUwMTIsImV4cCI6MjA5MTI5MTAxMn0.pv9usTh45zgn14cPiJV3EpnHHe0aZ_IDChD1OkHYJ38';

  const AppConfig({
    required this.supabaseUrl,
    required this.supabaseAnonKey,
    required this.defaultTimezone,
  });

  factory AppConfig.fromEnvironment() {
    return const AppConfig(
      supabaseUrl: String.fromEnvironment(
        'SUPABASE_URL',
        defaultValue: _defaultSupabaseUrl,
      ),
      supabaseAnonKey: String.fromEnvironment(
        'SUPABASE_ANON_KEY',
        defaultValue: _defaultSupabaseAnonKey,
      ),
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
