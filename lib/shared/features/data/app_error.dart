class MappedAppException implements Exception {
  const MappedAppException({required this.code, this.message, this.originalError});

  final String code;
  final String? message;
  final Object? originalError;

  @override
  String toString() => 'MappedAppException(code: $code, message: $message)';
}
