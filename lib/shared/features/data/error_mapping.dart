String parsePostgrestErrorCode({required dynamic error}) {
  final String? code = _readCode(error);
  if (code != null && code.isNotEmpty) {
    return code;
  }

  final String? detailsCode = _readDetailsAppErrorCode(error);
  if (detailsCode != null && detailsCode.isNotEmpty) {
    return detailsCode;
  }

  final String? message = _readMessage(error);
  if (message != null && message.isNotEmpty) {
    final String? parsed = _extractCodeFromText(message);
    if (parsed != null) {
      return parsed;
    }
  }

  return 'INTERNAL_ERROR';
}

String? _readCode(dynamic error) {
  if (error is Map<String, dynamic>) {
    final dynamic value = error['code'];
    return value is String ? value : null;
  }
  try {
    final dynamic value = (error as dynamic).code;
    return value is String ? value : null;
  } catch (_) {
    return null;
  }
}

String? _readDetailsAppErrorCode(dynamic error) {
  if (error is Map<String, dynamic>) {
    return _extractAppErrorCode(error['details']);
  }
  try {
    final dynamic value = (error as dynamic).details;
    return _extractAppErrorCode(value);
  } catch (_) {
    return null;
  }
}

String? _readMessage(dynamic error) {
  if (error is Map<String, dynamic>) {
    final dynamic value = error['message'];
    return value is String ? value : null;
  }
  try {
    final dynamic value = (error as dynamic).message;
    return value is String ? value : null;
  } catch (_) {
    return null;
  }
}

String? _extractAppErrorCode(dynamic details) {
  if (details is Map<String, dynamic>) {
    final dynamic value = details['APP_ERROR_CODE'];
    return value is String ? value : null;
  }
  if (details is String) {
    return _extractCodeFromText(details);
  }
  return null;
}

String? _extractCodeFromText(String text) {
  final RegExp directCode = RegExp(r'\b([A-Z][A-Z0-9_]{2,})\b');
  final Match? directMatch = directCode.firstMatch(text);
  if (directMatch == null) {
    return null;
  }

  final String? candidate = directMatch.group(1);
  if (candidate == null || candidate.isEmpty) {
    return null;
  }

  if (_knownAppCodes.contains(candidate)) {
    return candidate;
  }
  return null;
}

const Set<String> _knownAppCodes = <String>{
  'UNAUTHORIZED',
  'FORBIDDEN',
  'INVALID_ARGUMENT',
  'INTERNAL_ERROR',
  'STAR_NOT_FOUND',
  'DAILY_STAR_LIMIT_EXCEEDED',
  'DAILY_REACTION_LIMIT_EXCEEDED',
  'ALREADY_REACTED',
  'BLOCKED_RELATIONSHIP',
  'SELF_REACTION_NOT_ALLOWED',
  'NUDGE_NOT_FOUND',
  'NUDGE_OUT_OF_WINDOW',
  'NUDGE_DAILY_LIMIT_EXCEEDED',
  'TAG_LIMIT_EXCEEDED',
  'CONTENT_TOO_LONG',
  'CONTENT_BLOCKED_WORD',
  'UNAUTHENTICATED',
  'SESSION_EXPIRED',
  'PROFILE_INCOMPLETE',
  'INVALID_NICKNAME',
  'NICKNAME_BLOCKED_WORD',
};
