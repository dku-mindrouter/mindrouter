enum AuthEventType { signedIn, signedOut, tokenRefreshed, userUpdated, unknown }

class AuthStatus {
  const AuthStatus({
    required this.isAuthenticated,
    this.userId,
    this.expiresAt,
    this.eventType = AuthEventType.unknown,
  });

  final bool isAuthenticated;
  final String? userId;
  final DateTime? expiresAt;
  final AuthEventType eventType;
}
