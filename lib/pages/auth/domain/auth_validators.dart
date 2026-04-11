import 'auth_exception.dart';

class AuthValidators {
  static const Set<String> _blockedWords = {
    'admin',
    'operator',
    'fuck',
    'shit',
    '병신',
    '시발',
  };

  static Future<void> checkAuthenticatedUser({required String? userId}) async {
    if (userId == null || userId.trim().isEmpty) {
      throw const AuthException(AuthErrorCode.unauthenticated);
    }
  }

  static Future<void> checkSessionValidity({required DateTime? expiresAt}) async {
    if (expiresAt == null || expiresAt.isBefore(DateTime.now().toUtc())) {
      throw const AuthException(AuthErrorCode.sessionExpired);
    }
  }

  static Future<void> checkProfileCompleted({required String? nickname}) async {
    if (nickname == null || nickname.trim().isEmpty) {
      throw const AuthException(AuthErrorCode.profileIncomplete);
    }
  }

  static Future<void> checkNicknamePolicy({required String nickname}) async {
    final String normalized = nickname.trim();
    if (normalized.length < 2 || normalized.length > 24) {
      throw const AuthException(AuthErrorCode.invalidNickname);
    }

    final RegExp pattern = RegExp(r'^[a-zA-Z0-9가-힣_]+$');
    if (!pattern.hasMatch(normalized)) {
      throw const AuthException(AuthErrorCode.invalidNickname);
    }

    final String lowered = normalized.toLowerCase();
    for (final String blockedWord in _blockedWords) {
      if (lowered.contains(blockedWord)) {
        throw const AuthException(AuthErrorCode.nicknameBlockedWord);
      }
    }
  }
}
