import '../../../shared/features/data/app_error.dart';
import '../../../shared/features/data/execute_with_error_mapping.dart';
import '../../../shared/features/data/with_retry.dart';
import '../domain/auth_exception.dart';
import 'auth_data_source.dart';

class ProfileRepository {
  ProfileRepository({required AuthDataSource dataSource}) : _dataSource = dataSource;

  final AuthDataSource _dataSource;

  Future<Map<String, dynamic>?> getProfileByUserId({required String userId}) async {
    return withRetry(
      task: () => executeWithErrorMapping<Map<String, dynamic>?>(
        action: () {
          return _dataSource.getProfileByUserId(userId: userId);
        },
      ),
      maxRetryCount: 2,
      shouldRetry:
          (Object error) =>
              error is MappedAppException &&
              error.code == AuthErrorCode.internalError,
    );
  }

  Future<void> upsertProfile({
    required String userId,
    required String nickname,
    required String timezone,
  }) async {
    await withRetry(
      task: () => executeWithErrorMapping<void>(
        action: () async {
          await _dataSource.upsertProfile(
            userId: userId,
            nickname: nickname,
            timezone: timezone,
          );
        },
      ),
      maxRetryCount: 2,
      shouldRetry:
          (Object error) =>
              error is MappedAppException &&
              error.code == AuthErrorCode.internalError,
    );
  }

  Future<void> updatePushToken({
    required String userId,
    required String pushToken,
  }) async {
    await withRetry(
      task: () => executeWithErrorMapping<void>(
        action: () async {
          await _dataSource.updatePushToken(
            userId: userId,
            pushToken: pushToken,
          );
        },
      ),
      maxRetryCount: 2,
      shouldRetry:
          (Object error) =>
              error is MappedAppException &&
              error.code == AuthErrorCode.internalError,
    );
  }

  Future<void> ensureActiveProfile({required String userId}) async {
    final Map<String, dynamic>? profile =
        await getProfileByUserId(userId: userId);

    if (profile == null) {
      throw const AuthException(AuthErrorCode.unauthorized);
    }

    final bool isActive = profile['is_active'] == true;
    if (!isActive) {
      throw const AuthException(AuthErrorCode.forbidden);
    }
  }

  AuthException mapToAuthException(Object error) {
    if (error is MappedAppException) {
      return AuthException(error.code, message: error.message);
    }
    if (error is AuthException) {
      return error;
    }
    return AuthException(AuthErrorCode.internalError, message: error.toString());
  }
}
