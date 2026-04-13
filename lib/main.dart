import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'app/app_bootstrap.dart';
import 'app/app_config.dart';
import 'app/figma_wireframe_experience.dart';
import 'pages/auth/data/auth_repository.dart';
import 'pages/auth/data/profile_repository.dart';
import 'pages/auth/data/supabase_auth_data_source.dart';
import 'pages/auth/domain/auth_route_policy.dart';
import 'pages/auth/domain/auth_validators.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  final AppConfig config = AppConfig.fromEnvironment();
  final AppBootstrap bootstrap = await AppBootstrapper(
    config: config,
  ).bootstrap();

  runApp(MyApp(bootstrap: bootstrap));
}

class MyApp extends StatelessWidget {
  const MyApp({super.key, required this.bootstrap});

  final AppBootstrap bootstrap;

  @override
  Widget build(BuildContext context) {
    final ColorScheme colorScheme = ColorScheme.fromSeed(
      seedColor: const Color(0xFF6366F1),
      brightness: Brightness.dark,
    );

    return MaterialApp(
      title: 'MindfulConnect',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: colorScheme,
        scaffoldBackgroundColor: const Color(0xFF0A0B14),
        useMaterial3: true,
        snackBarTheme: const SnackBarThemeData(
          behavior: SnackBarBehavior.floating,
        ),
        textTheme: Typography.whiteMountainView.apply(
          bodyColor: Colors.white,
          displayColor: Colors.white,
        ),
      ),
      home: AppEntryPage(bootstrap: bootstrap),
    );
  }
}

class AppEntryPage extends StatelessWidget {
  const AppEntryPage({super.key, required this.bootstrap});

  final AppBootstrap bootstrap;

  @override
  Widget build(BuildContext context) {
    if (bootstrap.status == AppBootstrapStatus.missingConfig) {
      return BootStatusPage(
        title: 'MindfulConnect',
        headline: 'Supabase 설정이 필요합니다.',
        description:
            '앱은 정상적으로 부팅되지만, 실제 인증 흐름을 실행하려면 SUPABASE_URL 과 SUPABASE_ANON_KEY 가 필요합니다.',
        primaryLabel: 'Config Needed',
        detailItems: const <String>[
          'dart-define 로 SUPABASE_URL 전달',
          'dart-define 로 SUPABASE_ANON_KEY 전달',
          '필요하면 APP_DEFAULT_TIMEZONE 도 함께 전달',
        ],
      );
    }

    if (bootstrap.status == AppBootstrapStatus.failed) {
      return BootStatusPage(
        title: 'MindfulConnect',
        headline: 'Supabase 초기화에 실패했습니다.',
        description: bootstrap.errorMessage ?? '초기화 중 알 수 없는 오류가 발생했습니다.',
        primaryLabel: 'Retry Setup',
        detailItems: const <String>[
          'Supabase URL 과 anon key 확인',
          '프로젝트 네트워크 접근 가능 여부 확인',
          '앱을 다시 실행해서 초기화 재시도',
        ],
      );
    }

    return AuthGatePage(defaultTimezone: bootstrap.config.defaultTimezone);
  }
}

class AuthGatePage extends StatefulWidget {
  const AuthGatePage({super.key, required this.defaultTimezone});

  final String defaultTimezone;

  @override
  State<AuthGatePage> createState() => _AuthGatePageState();
}

class _AuthGatePageState extends State<AuthGatePage> {
  late final Future<AuthGateResult> _future = _signInAndPrepareProfile();

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<AuthGateResult>(
      future: _future,
      builder: (BuildContext context, AsyncSnapshot<AuthGateResult> snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          return const BootStatusPage(
            title: 'MindfulConnect',
            headline: '인증 진입 흐름을 준비하고 있습니다.',
            description: 'Supabase 연결, 익명 로그인, 기본 프로필 확인을 순서대로 진행하는 중입니다.',
            primaryLabel: 'Connecting',
            detailItems: <String>[
              'Supabase 세션 확인',
              '익명 로그인 보장',
              'profiles 기본 데이터 확인',
            ],
          );
        }

        if (snapshot.hasError) {
          final String message = snapshot.error.toString();
          return BootStatusPage(
            title: 'MindfulConnect',
            headline: 'auth 진입 흐름에서 문제가 발생했습니다.',
            description: message,
            primaryLabel: 'Auth Blocked',
            detailItems: const <String>[
              'anonymous auth 활성화 여부 확인',
              'profiles 테이블/RLS 확인',
              'backend handoff 문서 기준 계약 확인',
            ],
          );
        }

        final AuthGateResult result = snapshot.data!;
        return SignedInHomePage(result: result);
      },
    );
  }

  Future<AuthGateResult> _signInAndPrepareProfile() async {
    final SupabaseClient client = Supabase.instance.client;
    final SupabaseAuthDataSource dataSource = SupabaseAuthDataSource(
      client: client,
    );
    final AuthRepository authRepository = AuthRepository(
      dataSource: dataSource,
    );
    final ProfileRepository profileRepository = ProfileRepository(
      dataSource: dataSource,
    );

    if (client.auth.currentUser == null) {
      await authRepository.signInForDevelopment();
    }

    final Session? session = client.auth.currentSession;
    final User? user = client.auth.currentUser;

    await AuthValidators.checkAuthenticatedUser(userId: user?.id);
    await AuthValidators.checkSessionValidity(
      expiresAt: _parseSessionExpiry(session),
    );

    final String userId = user!.id;
    Map<String, dynamic>? profile = await profileRepository.getProfileByUserId(
      userId: userId,
    );

    if (profile == null) {
      final String nickname = _buildDefaultNickname(userId);
      await AuthValidators.checkNicknamePolicy(nickname: nickname);
      await profileRepository.upsertProfile(
        userId: userId,
        nickname: nickname,
        timezone: widget.defaultTimezone,
      );
      profile = await profileRepository.getProfileByUserId(userId: userId);
    }

    await profileRepository.ensureActiveProfile(userId: userId);
    await AuthValidators.checkProfileCompleted(
      nickname: profile?['nickname'] as String?,
    );

    return AuthGateResult(
      userId: userId,
      nickname:
          profile?['nickname'] as String? ?? _buildDefaultNickname(userId),
      timezone: profile?['timezone'] as String? ?? widget.defaultTimezone,
      nextRoute: resolveAuthNextRoute(),
    );
  }

  DateTime? _parseSessionExpiry(Session? session) {
    final int? expiresAt = session?.expiresAt;
    if (expiresAt == null) {
      return null;
    }
    return DateTime.fromMillisecondsSinceEpoch(expiresAt * 1000, isUtc: true);
  }

  String _buildDefaultNickname(String userId) {
    final String normalized = userId.replaceAll('-', '');
    final String suffix = normalized.substring(0, 8);
    return 'mind_$suffix';
  }
}

class AuthGateResult {
  const AuthGateResult({
    required this.userId,
    required this.nickname,
    required this.timezone,
    required this.nextRoute,
  });

  final String userId;
  final String nickname;
  final String timezone;
  final String nextRoute;
}

class SignedInHomePage extends StatelessWidget {
  const SignedInHomePage({super.key, required this.result});

  final AuthGateResult result;

  @override
  Widget build(BuildContext context) {
    return FigmaWireframeExperience(
      userId: result.userId,
      nickname: result.nickname,
      timezone: result.timezone,
      nextRoute: result.nextRoute,
    );
  }
}

class BootStatusPage extends StatelessWidget {
  const BootStatusPage({
    super.key,
    required this.title,
    required this.headline,
    required this.description,
    required this.primaryLabel,
    required this.detailItems,
  });

  final String title;
  final String headline;
  final String description;
  final String primaryLabel;
  final List<String> detailItems;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);

    return Scaffold(
      backgroundColor: const Color(0xFF0A0B14),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Text(
                title,
                style: theme.textTheme.headlineMedium?.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                headline,
                style: theme.textTheme.titleLarge?.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                description,
                style: theme.textTheme.bodyLarge?.copyWith(
                  color: Colors.white.withValues(alpha: 0.72),
                ),
              ),
              const SizedBox(height: 24),
              Expanded(
                child: ListView.separated(
                  itemCount: detailItems.length,
                  separatorBuilder: (_, _) => const SizedBox(height: 12),
                  itemBuilder: (BuildContext context, int index) {
                    return _StatusCard(
                      title: 'Step ${index + 1}',
                      description: detailItems[index],
                    );
                  },
                ),
              ),
              const SizedBox(height: 16),
              FilledButton(
                onPressed: () {},
                style: FilledButton.styleFrom(
                  backgroundColor: const Color(0xFF6366F1),
                  foregroundColor: Colors.white,
                ),
                child: Text(primaryLabel),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _StatusCard extends StatelessWidget {
  const _StatusCard({required this.title, required this.description});

  final String title;
  final String description;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.04),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
        boxShadow: const <BoxShadow>[
          BoxShadow(
            color: Color(0x22000000),
            blurRadius: 20,
            offset: Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(
            title,
            style: theme.textTheme.titleMedium?.copyWith(
              color: Colors.white,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            description,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: Colors.white.withValues(alpha: 0.72),
              height: 1.45,
            ),
          ),
        ],
      ),
    );
  }
}
