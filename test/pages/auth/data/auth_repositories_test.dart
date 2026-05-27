import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:mindfulconnect/pages/auth/data/auth_data_source.dart';
import 'package:mindfulconnect/pages/auth/data/auth_repository.dart';
import 'package:mindfulconnect/pages/auth/data/profile_repository.dart';
import 'package:mindfulconnect/pages/auth/domain/auth_exception.dart';
import 'package:mindfulconnect/pages/auth/domain/auth_status.dart';
import 'package:mindfulconnect/shared/features/data/app_error.dart';

class FakeAuthDataSource implements AuthDataSource {
  final StreamController<AuthStatus> _streamController =
      StreamController<AuthStatus>.broadcast();

  int signInCount = 0;
  int refreshCount = 0;
  int signOutCount = 0;
  int profileReadCount = 0;
  int upsertCount = 0;
  int tokenUpdateCount = 0;

  Object? signInError;
  Object? refreshError;
  Object? signOutError;
  Object? profileError;
  Map<String, dynamic>? profile;

  @override
  Stream<AuthStatus> authStateChanges() => _streamController.stream;

  void emit(AuthStatus status) {
    _streamController.add(status);
  }

  @override
  Future<void> signInAnonymously() async {
    signInCount += 1;
    if (signInError != null) {
      throw signInError!;
    }
  }

  @override
  Future<void> refreshSession() async {
    refreshCount += 1;
    if (refreshError != null) {
      throw refreshError!;
    }
  }

  @override
  Future<void> signOut() async {
    signOutCount += 1;
    if (signOutError != null) {
      throw signOutError!;
    }
  }

  @override
  Future<Map<String, dynamic>?> getProfileByUserId({
    required String userId,
  }) async {
    profileReadCount += 1;
    if (profileError != null) {
      throw profileError!;
    }
    return profile;
  }

  @override
  Future<void> upsertProfile({
    required String userId,
    required String nickname,
    required String timezone,
  }) async {
    upsertCount += 1;
  }

  @override
  Future<void> updatePushToken({
    required String userId,
    required String? pushToken,
  }) async {
    tokenUpdateCount += 1;
  }

  Future<void> dispose() async {
    await _streamController.close();
  }
}

void main() {
  group('AuthRepository/ProfileRepository', () {
    late FakeAuthDataSource dataSource;
    late AuthRepository authRepository;
    late ProfileRepository profileRepository;

    setUp(() {
      dataSource = FakeAuthDataSource();
      authRepository = AuthRepository(dataSource: dataSource);
      profileRepository = ProfileRepository(dataSource: dataSource);
    });

    tearDown(() async {
      await dataSource.dispose();
    });

    test('authStateChanges forwards stream events', () async {
      final Future<AuthStatus> futureStatus = authRepository
          .authStateChanges()
          .first;

      dataSource.emit(
        const AuthStatus(
          isAuthenticated: true,
          userId: 'u1',
          eventType: AuthEventType.signedIn,
        ),
      );

      final AuthStatus status = await futureStatus;
      expect(status.isAuthenticated, isTrue);
      expect(status.userId, 'u1');
    });

    test(
      'signInForDevelopment retries transient errors up to max retry',
      () async {
        dataSource.signInError = Object();

        await expectLater(
          () => authRepository.signInForDevelopment(),
          throwsA(isA<MappedAppException>()),
        );

        expect(dataSource.signInCount, 3);
      },
    );

    test('refreshCurrentSession forwards refresh call', () async {
      await authRepository.refreshCurrentSession();

      expect(dataSource.refreshCount, 1);
    });

    test('mapToAuthException keeps mapped error code', () {
      final AuthException mapped = authRepository.mapToAuthException(
        const MappedAppException(code: 'UNAUTHORIZED'),
      );

      expect(mapped.code, 'UNAUTHORIZED');
    });

    test(
      'ensureActiveProfile throws unauthorized when profile not found',
      () async {
        dataSource.profile = null;

        await expectLater(
          () => profileRepository.ensureActiveProfile(userId: 'u1'),
          throwsA(
            isA<AuthException>().having(
              (AuthException error) => error.code,
              'code',
              AuthErrorCode.unauthorized,
            ),
          ),
        );
      },
    );

    test(
      'ensureActiveProfile throws forbidden when profile inactive',
      () async {
        dataSource.profile = {'id': 'u1', 'is_active': false};

        await expectLater(
          () => profileRepository.ensureActiveProfile(userId: 'u1'),
          throwsA(
            isA<AuthException>().having(
              (AuthException error) => error.code,
              'code',
              AuthErrorCode.forbidden,
            ),
          ),
        );
      },
    );

    test('ensureActiveProfile passes when profile active', () async {
      dataSource.profile = {'id': 'u1', 'is_active': true};

      await profileRepository.ensureActiveProfile(userId: 'u1');

      expect(dataSource.profileReadCount, 1);
    });
  });
}
