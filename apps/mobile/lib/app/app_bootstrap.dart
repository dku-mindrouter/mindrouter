import 'package:supabase_flutter/supabase_flutter.dart';

import '../core/config/app_env.dart';

class AppBootstrap {
  static Future<void> initialize() async {
    if (!AppEnv.hasSupabase) {
      return;
    }

    await Supabase.initialize(
      url: AppEnv.supabaseUrl,
      anonKey: AppEnv.supabaseAnonKey,
    );
  }
}

