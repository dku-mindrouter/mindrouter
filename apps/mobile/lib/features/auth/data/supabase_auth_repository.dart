import 'package:supabase_flutter/supabase_flutter.dart';

import '../domain/auth_state.dart';
import 'auth_repository.dart';

class SupabaseAuthRepository implements AuthRepository {
  SupabaseAuthRepository(this._client);

  final SupabaseClient _client;

  @override
  bool get isConfigured => true;

  @override
  Stream<AuthStatus> authStateChanges() async* {
    yield _client.auth.currentSession == null
        ? AuthStatus.unauthenticated
        : AuthStatus.authenticated;

    yield* _client.auth.onAuthStateChange.map((event) {
      return event.session == null
          ? AuthStatus.unauthenticated
          : AuthStatus.authenticated;
    });
  }

  @override
  Future<void> signInForDevelopment() async {
    await _client.auth.signInAnonymously();
  }

  @override
  Future<void> signOut() async {
    await _client.auth.signOut();
  }
}

