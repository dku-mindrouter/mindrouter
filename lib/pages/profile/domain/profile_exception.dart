class ProfileErrorCode {
  static const String unauthorized = 'UNAUTHORIZED';
  static const String forbidden = 'FORBIDDEN';
  static const String profileNotFound = 'PROFILE_NOT_FOUND';
  static const String statsInconsistent = 'STATS_INCONSISTENT';
  static const String internalError = 'INTERNAL_ERROR';
}

class ProfileException implements Exception {
  const ProfileException(this.code, {this.message});

  final String code;
  final String? message;

  @override
  String toString() => 'ProfileException(code: $code, message: $message)';
}
