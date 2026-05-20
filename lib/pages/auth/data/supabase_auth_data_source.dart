import 'package:supabase_flutter/supabase_flutter.dart';

import '../domain/auth_status.dart';
import 'auth_data_source.dart';

class SupabaseAuthDataSource implements AuthDataSource {
  SupabaseAuthDataSource({required SupabaseClient client}) : _client = client;

  final SupabaseClient _client;

  @override
  Stream<AuthStatus> authStateChanges() {
    return _client.auth.onAuthStateChange.map((AuthState event) {
      final Session? session = event.session;
      return AuthStatus(
        isAuthenticated: session?.user.id != null,
        userId: session?.user.id,
        expiresAt: _parseExpiresAt(session),
        eventType: _mapEventType(event.event),
      );
    });
  }

  @override
  Future<void> signInAnonymously() async {
    await _client.auth.signInAnonymously();
  }

  @override
  Future<void> signOut() async {
    await _client.auth.signOut();
  }

  @override
  Future<Map<String, dynamic>?> getProfileByUserId({
    required String userId,
  }) async {
    final dynamic response = await _client
        .from('profiles')
        .select('id,nickname,timezone,is_active,push_token')
        .eq('id', userId)
        .maybeSingle();

    if (response is Map<String, dynamic>) {
      return response;
    }
    return null;
  }

  @override
  Future<void> upsertProfile({
    required String userId,
    required String nickname,
    required String timezone,
  }) async {
    await _client.from('profiles').upsert({
      'id': userId,
      'nickname': nickname,
      'timezone': timezone,
    }, onConflict: 'id');
  }

  @override
  Future<void> updatePushToken({
    required String userId,
    required String? pushToken,
  }) async {
    await _client
        .from('profiles')
        .update({'push_token': pushToken})
        .eq('id', userId);
  }

  DateTime? _parseExpiresAt(Session? session) {
    final int? expiresAt = session?.expiresAt;
    if (expiresAt == null) {
      return null;
    }
    return DateTime.fromMillisecondsSinceEpoch(expiresAt * 1000, isUtc: true);
  }

  AuthEventType _mapEventType(AuthChangeEvent event) {
    switch (event) {
      case AuthChangeEvent.signedIn:
        return AuthEventType.signedIn;
      case AuthChangeEvent.signedOut:
        return AuthEventType.signedOut;
      case AuthChangeEvent.tokenRefreshed:
        return AuthEventType.tokenRefreshed;
      case AuthChangeEvent.userUpdated:
        return AuthEventType.userUpdated;
      default:
        return AuthEventType.unknown;
    }
  }
}
