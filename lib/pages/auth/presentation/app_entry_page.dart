import 'dart:async';

import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../app/app_bootstrap.dart';
import '../../../app/figma_wireframe_experience.dart';
import '../../../shared/features/data/app_error.dart';
import '../data/auth_repository.dart';
import '../data/profile_repository.dart';
import '../data/push_notification_registrar.dart';
import '../data/supabase_auth_data_source.dart';
import '../domain/auth_exception.dart' as domain_auth;
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
  static const Duration _retryDelay = Duration(milliseconds: 900);

  late Future<AuthGateResult> _future;
  bool _retryScheduled = false;

  @override
  void initState() {
    super.initState();
    _future = _signInAndPrepareProfile();
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<AuthGateResult>(
      future: _future,
      builder: (BuildContext context, AsyncSnapshot<AuthGateResult> snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          return const AppLoadingPage(message: '세션과 프로필을 확인하고 있어요.');
        }

        if (snapshot.hasError) {
          _scheduleAuthGateRetry();
          return const AppLoadingPage(message: '세션을 다시 연결하고 있어요.');
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

    for (int attempt = 0; attempt < 3; attempt += 1) {
      try {
        return await _prepareProfileOnce(
          client: client,
          authRepository: authRepository,
          profileRepository: profileRepository,
        );
      } catch (error) {
        if (!_shouldRecoverAuthGateError(error) || attempt == 2) {
          rethrow;
        }

        await Future<void>.delayed(_retryDelay);
      }
    }

    throw StateError('Auth gate retry loop ended without a result.');
  }

  Future<AuthGateResult> _prepareProfileOnce({
    required SupabaseClient client,
    required AuthRepository authRepository,
    required ProfileRepository profileRepository,
  }) async {
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

  void _scheduleAuthGateRetry() {
    if (_retryScheduled) {
      return;
    }

    _retryScheduled = true;
    Future<void>.delayed(_retryDelay, () {
      if (!mounted) {
        return;
      }
      setState(() {
        _retryScheduled = false;
        _future = _signInAndPrepareProfile();
      });
    });
  }

  Future<void> _ensureValidSession({
    required SupabaseClient client,
    required AuthRepository authRepository,
  }) async {
    if (_hasValidSession(client.auth.currentSession)) {
      return;
    }

    if (client.auth.currentUser != null || client.auth.currentSession != null) {
      try {
        await authRepository.refreshCurrentSession();
      } catch (_) {
        // Existing anonymous accounts must not be replaced silently.
        // If refresh fails, the auth gate retries the same account path.
      }

      if (_hasValidSession(client.auth.currentSession)) {
        return;
      }

      throw const domain_auth.AuthException(
        domain_auth.AuthErrorCode.sessionExpired,
      );
    }

    try {
      await authRepository.signInForDevelopment();
      if (_hasValidSession(client.auth.currentSession)) {
        return;
      }
    } catch (_) {
      throw const domain_auth.AuthException(
        domain_auth.AuthErrorCode.unauthenticated,
      );
    }

    throw const domain_auth.AuthException(
      domain_auth.AuthErrorCode.sessionExpired,
    );
  }

  bool _shouldRecoverAuthGateError(Object error) {
    if (error is MappedAppException) {
      return error.code == '42501' ||
          error.code == domain_auth.AuthErrorCode.unauthorized ||
          error.code == domain_auth.AuthErrorCode.forbidden ||
          error.code == domain_auth.AuthErrorCode.unauthenticated ||
          error.code == domain_auth.AuthErrorCode.sessionExpired ||
          _looksLikeProfileRlsError(error.message);
    }

    if (error is domain_auth.AuthException) {
      return error.code == domain_auth.AuthErrorCode.unauthorized ||
          error.code == domain_auth.AuthErrorCode.forbidden ||
          error.code == domain_auth.AuthErrorCode.unauthenticated ||
          error.code == domain_auth.AuthErrorCode.sessionExpired ||
          error.code == domain_auth.AuthErrorCode.profileIncomplete;
    }

    return _looksLikeProfileRlsError(error.toString());
  }

  bool _looksLikeProfileRlsError(String? message) {
    final String text = message?.toLowerCase() ?? '';
    return text.contains('42501') ||
        (text.contains('row-level security') && text.contains('profiles'));
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
