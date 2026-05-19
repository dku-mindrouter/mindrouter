class NudgeErrorCode {
  static const String unauthorized = 'UNAUTHORIZED';
  static const String forbidden = 'FORBIDDEN';
  static const String nudgeNotFound = 'NUDGE_NOT_FOUND';
  static const String invalidArgument = 'INVALID_ARGUMENT';
  static const String internalError = 'INTERNAL_ERROR';
}

class NudgeException implements Exception {
  const NudgeException(this.code, {this.message});

  final String code;
  final String? message;

  @override
  String toString() => 'NudgeException(code: $code, message: $message)';
}
