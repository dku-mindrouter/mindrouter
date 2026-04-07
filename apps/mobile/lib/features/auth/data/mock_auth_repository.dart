import 'dart:async';

import '../domain/auth_state.dart';
import 'auth_repository.dart';

class MockAuthRepository implements AuthRepository {
  MockAuthRepository() {
    _controller = StreamController<AuthStatus>.broadcast(
      onListen: () => _controller.add(_status),
    );
  }

  late final StreamController<AuthStatus> _controller;
  AuthStatus _status = AuthStatus.unauthenticated;

  @override
  bool get isConfigured => false;

  @override
  Stream<AuthStatus> authStateChanges() => _controller.stream;

  @override
  Future<void> signInForDevelopment() async {
    _status = AuthStatus.authenticated;
    _controller.add(_status);
  }

  @override
  Future<void> signOut() async {
    _status = AuthStatus.unauthenticated;
    _controller.add(_status);
  }
}

