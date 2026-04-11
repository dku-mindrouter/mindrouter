class AuthErrorCode {
  static const String unauthenticated = 'UNAUTHENTICATED';
  static const String sessionExpired = 'SESSION_EXPIRED';
  static const String profileIncomplete = 'PROFILE_INCOMPLETE';
  static const String invalidNickname = 'INVALID_NICKNAME';
  static const String nicknameBlockedWord = 'NICKNAME_BLOCKED_WORD';
  static const String unauthorized = 'UNAUTHORIZED';
  static const String forbidden = 'FORBIDDEN';
  static const String internalError = 'INTERNAL_ERROR';
}

class AuthException implements Exception {
  const AuthException(this.code, {this.message});

  final String code;
  final String? message;

  @override
  String toString() => 'AuthException(code: $code, message: $message)';
}
