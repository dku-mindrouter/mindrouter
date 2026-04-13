import 'package:supabase_flutter/supabase_flutter.dart';

import 'app_config.dart';

class AppBootstrap {
  const AppBootstrap._({
    required this.config,
    required this.status,
    this.errorMessage,
  });

  factory AppBootstrap.ready({required AppConfig config}) {
    return AppBootstrap._(
      config: config,
      status: AppBootstrapStatus.ready,
    );
  }

  factory AppBootstrap.missingConfig({required AppConfig config}) {
    return AppBootstrap._(
      config: config,
      status: AppBootstrapStatus.missingConfig,
      errorMessage: 'Supabase 설정값이 아직 연결되지 않았습니다.',
    );
  }

  factory AppBootstrap.failed({
    required AppConfig config,
    required String errorMessage,
  }) {
    return AppBootstrap._(
      config: config,
      status: AppBootstrapStatus.failed,
      errorMessage: errorMessage,
    );
  }

  final AppConfig config;
  final AppBootstrapStatus status;
  final String? errorMessage;

  bool get isReady => status == AppBootstrapStatus.ready;
}

enum AppBootstrapStatus {
  ready,
  missingConfig,
  failed,
}

class AppBootstrapper {
  const AppBootstrapper({required AppConfig config}) : _config = config;

  final AppConfig _config;

  Future<AppBootstrap> bootstrap() async {
    if (!_config.hasSupabaseConfig) {
      return AppBootstrap.missingConfig(config: _config);
    }

    try {
      await Supabase.initialize(
        url: _config.supabaseUrl,
        anonKey: _config.supabaseAnonKey,
      );
      return AppBootstrap.ready(config: _config);
    } catch (error) {
      return AppBootstrap.failed(
        config: _config,
        errorMessage: 'Supabase 초기화에 실패했습니다: $error',
      );
    }
  }
}
