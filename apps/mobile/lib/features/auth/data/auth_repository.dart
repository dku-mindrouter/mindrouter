import '../domain/auth_state.dart';

abstract class AuthRepository {
  bool get isConfigured;
  Stream<AuthStatus> authStateChanges();
  Future<void> signInForDevelopment();
  Future<void> signOut();
}

