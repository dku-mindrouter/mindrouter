import '../domain/auth_status.dart';

abstract class AuthDataSource {
  Stream<AuthStatus> authStateChanges();

  Future<void> signInAnonymously();

  Future<void> refreshSession();

  Future<void> signOut();

  Future<Map<String, dynamic>?> getProfileByUserId({required String userId});

  Future<void> upsertProfile({
    required String userId,
    required String nickname,
    required String timezone,
  });

  Future<void> updatePushToken({
    required String userId,
    required String? pushToken,
  });
}
