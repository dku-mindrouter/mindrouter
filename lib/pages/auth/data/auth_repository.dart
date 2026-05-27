import '../../../shared/features/data/app_error.dart';
import '../../../shared/features/data/execute_with_error_mapping.dart';
import '../../../shared/features/data/with_retry.dart';
import '../domain/auth_exception.dart';
import '../domain/auth_status.dart';
import 'auth_data_source.dart';

class AuthRepository {
  AuthRepository({required AuthDataSource dataSource})
    : _dataSource = dataSource;

  final AuthDataSource _dataSource;

  Stream<AuthStatus> authStateChanges() {
    return _dataSource.authStateChanges();
  }

  Future<void> signInForDevelopment() async {
    await withRetry(
      task: () => executeWithErrorMapping<void>(
        action: () async {
          await _dataSource.signInAnonymously();
        },
      ),
      maxRetryCount: 2,
      shouldRetry: (Object error) =>
          error is MappedAppException &&
          error.code == AuthErrorCode.internalError,
    );
  }

  Future<void> refreshCurrentSession() async {
    await withRetry(
      task: () => executeWithErrorMapping<void>(
        action: () async {
          await _dataSource.refreshSession();
        },
      ),
      maxRetryCount: 1,
      shouldRetry: (Object error) =>
          error is MappedAppException &&
          error.code == AuthErrorCode.internalError,
    );
  }

  Future<void> signOut() async {
    await withRetry(
      task: () => executeWithErrorMapping<void>(
        action: () async {
          await _dataSource.signOut();
        },
      ),
      maxRetryCount: 2,
      shouldRetry: (Object error) =>
          error is MappedAppException &&
          error.code == AuthErrorCode.internalError,
    );
  }

  AuthException mapToAuthException(Object error) {
    if (error is MappedAppException) {
      return AuthException(error.code, message: error.message);
    }
    return AuthException(
      AuthErrorCode.internalError,
      message: error.toString(),
    );
  }
}
