import 'dart:async';

import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../app/app_bootstrap.dart';
import '../../../app/figma_wireframe_experience.dart';
import '../data/auth_repository.dart';
import '../data/profile_repository.dart';
import '../data/push_notification_registrar.dart';
import '../data/supabase_auth_data_source.dart';
import '../domain/auth_route_policy.dart';
import '../domain/auth_validators.dart';
import 'app_loading_page.dart';
import 'boot_status_page.dart';

class AppEntryPage extends StatelessWidget {
  const AppEntryPage({super.key, required this.bootstrap});

  final AppBootstrap bootstrap;

  @override
  Widget build(BuildContext context) {
    if (bootstrap.status == AppBootstrapStatus.missingConfig) {
      return FigmaWireframeExperience(
        userId: 'preview-user',
        nickname: 'preview_guest',
        timezone: bootstrap.config.defaultTimezone,
        nextRoute: 'emotion',
        previewMessage:
            'Supabase 설정 없이 프론트 화면을 확인할 수 있는 미리보기 모드입니다. 저장, 추천, 피드 조회는 mock 상태로 동작합니다.',
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
          return const AppLoadingPage(message: '세션과 프로필을 확인하고 있어요.');
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

    await _ensureValidSession(client: client, authRepository: authRepository);

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

  Future<void> _ensureValidSession({
    required SupabaseClient client,
    required AuthRepository authRepository,
  }) async {
    if (_hasValidSession(client.auth.currentSession)) {
      return;
    }

    try {
      await authRepository.signInForDevelopment();
      if (_hasValidSession(client.auth.currentSession)) {
        return;
      }
    } catch (_) {
      // Stale local auth state can keep currentUser while the session is dead.
      // Clear it best-effort, then create a fresh anonymous session below.
    }

    try {
      await authRepository.signOut();
    } catch (_) {
      // Local cleanup is best-effort; re-login is the required recovery path.
    }

    await authRepository.signInForDevelopment();
  }

  bool _hasValidSession(Session? session) {
    final DateTime? expiresAt = _parseSessionExpiry(session);
    if (expiresAt == null) {
      return false;
    }
    return expiresAt.isAfter(DateTime.now().toUtc());
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

class SignedInHomePage extends StatefulWidget {
  const SignedInHomePage({super.key, required this.result});

  final AuthGateResult result;

  @override
  State<SignedInHomePage> createState() => _SignedInHomePageState();
}

class _SignedInHomePageState extends State<SignedInHomePage> {
  late final PushNotificationRegistrar _pushNotificationRegistrar;

  @override
  void initState() {
    super.initState();

    final SupabaseAuthDataSource dataSource = SupabaseAuthDataSource(
      client: Supabase.instance.client,
    );
    final ProfileRepository profileRepository = ProfileRepository(
      dataSource: dataSource,
    );
    _pushNotificationRegistrar = PushNotificationRegistrar(
      profileRepository: profileRepository,
    );

    unawaited(_syncPushTokenIfAlreadyAllowed());
  }

  @override
  void dispose() {
    unawaited(_pushNotificationRegistrar.dispose());
    super.dispose();
  }

  Future<void> _syncPushTokenIfAlreadyAllowed() async {
    try {
      await _pushNotificationRegistrar.syncTokenIfAuthorized(
        userId: widget.result.userId,
      );
    } catch (_) {
      // Push token sync is best-effort and must not block app entry.
    }
  }

  @override
  Widget build(BuildContext context) {
    return FigmaWireframeExperience(
      userId: widget.result.userId,
      nickname: widget.result.nickname,
      timezone: widget.result.timezone,
      nextRoute: widget.result.nextRoute,
      notificationRegistrar: _pushNotificationRegistrar,
    );
  }
}
