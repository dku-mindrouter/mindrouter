class ComfortErrorCode {
  static const String unauthorized = 'UNAUTHORIZED';
  static const String forbidden = 'FORBIDDEN';
  static const String internalError = 'INTERNAL_ERROR';
}

class ComfortException implements Exception {
  const ComfortException(this.code, {this.message});

  final String code;
  final String? message;

  @override
  String toString() => 'ComfortException(code: $code, message: $message)';
}
