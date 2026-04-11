class ConstellationErrorCode {
  static const String unauthorized = 'UNAUTHORIZED';
  static const String forbidden = 'FORBIDDEN';
  static const String starNotFound = 'STAR_NOT_FOUND';
  static const String blockedRelationship = 'BLOCKED_RELATIONSHIP';
  static const String invalidArgument = 'INVALID_ARGUMENT';
  static const String internalError = 'INTERNAL_ERROR';
}

class ConstellationException implements Exception {
  const ConstellationException(this.code, {this.message});

  final String code;
  final String? message;

  @override
  String toString() => 'ConstellationException(code: $code, message: $message)';
}
