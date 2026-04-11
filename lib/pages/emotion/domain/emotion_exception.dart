class EmotionErrorCode {
  static const String unauthorized = 'UNAUTHORIZED';
  static const String forbidden = 'FORBIDDEN';
  static const String tagLimitExceeded = 'TAG_LIMIT_EXCEEDED';
  static const String contentTooLong = 'CONTENT_TOO_LONG';
  static const String contentBlockedWord = 'CONTENT_BLOCKED_WORD';
  static const String dailyStarLimitExceeded = 'DAILY_STAR_LIMIT_EXCEEDED';
  static const String invalidArgument = 'INVALID_ARGUMENT';
  static const String internalError = 'INTERNAL_ERROR';
}

class EmotionException implements Exception {
  const EmotionException(this.code, {this.message});

  final String code;
  final String? message;

  @override
  String toString() => 'EmotionException(code: $code, message: $message)';
}
