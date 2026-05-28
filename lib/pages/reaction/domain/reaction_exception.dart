class ReactionErrorCode {
  static const String unauthorized = 'UNAUTHORIZED';
  static const String forbidden = 'FORBIDDEN';
  static const String starNotFound = 'STAR_NOT_FOUND';
  static const String alreadyReacted = 'ALREADY_REACTED';
  static const String dailyReactionLimitExceeded =
      'DAILY_REACTION_LIMIT_EXCEEDED';
  static const String blockedRelationship = 'BLOCKED_RELATIONSHIP';
  static const String selfReactionNotAllowed = 'SELF_REACTION_NOT_ALLOWED';
  static const String letterBlockedByModeration =
      'LETTER_BLOCKED_BY_MODERATION';
  static const String letterModerationUnavailable =
      'LETTER_MODERATION_UNAVAILABLE';
  static const String invalidArgument = 'INVALID_ARGUMENT';
  static const String internalError = 'INTERNAL_ERROR';
}

class ReactionException implements Exception {
  const ReactionException(this.code, {this.message});

  final String code;
  final String? message;

  @override
  String toString() => 'ReactionException(code: $code, message: $message)';
}
