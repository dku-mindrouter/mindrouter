Map<String, dynamic> buildPaginationParams({
  required int limit,
  required int offset,
}) {
  final int normalizedLimit = limit < 1 ? 1 : limit;
  final int normalizedOffset = offset < 0 ? 0 : offset;
  return <String, dynamic>{
    'p_limit': normalizedLimit,
    'p_offset': normalizedOffset,
  };
}

DateTime mapUtcToUserTimezone({
  required DateTime utcTime,
  required String timezone,
}) {
  final DateTime utc = utcTime.toUtc();
  final int offsetMinutes = _resolveOffsetMinutes(timezone);
  return utc.add(Duration(minutes: offsetMinutes));
}

int _resolveOffsetMinutes(String timezone) {
  final String normalized = timezone.trim();
  if (normalized.isEmpty) {
    return _seoulOffsetMinutes;
  }

  final int? directOffset = _parseOffsetMinutes(normalized);
  if (directOffset != null) {
    return directOffset;
  }

  final int? mapped = _ianaOffsetMinutes[normalized];
  return mapped ?? _seoulOffsetMinutes;
}

int? _parseOffsetMinutes(String raw) {
  final RegExp offsetPattern = RegExp(
    r'^(?:UTC|GMT)?([+-])(\d{1,2})(?::?(\d{2}))?$',
  );
  final Match? match = offsetPattern.firstMatch(raw.toUpperCase());
  if (match == null) {
    return null;
  }

  final bool isNegative = match.group(1) == '-';
  final int hour = int.tryParse(match.group(2) ?? '') ?? 0;
  final int minute = int.tryParse(match.group(3) ?? '0') ?? 0;
  final int total = (hour * 60) + minute;
  return isNegative ? -total : total;
}

const int _seoulOffsetMinutes = 9 * 60;

const Map<String, int> _ianaOffsetMinutes = <String, int>{
  'Asia/Seoul': 9 * 60,
  'Asia/Tokyo': 9 * 60,
  'Asia/Shanghai': 8 * 60,
  'Asia/Singapore': 8 * 60,
  'Asia/Bangkok': 7 * 60,
  'Asia/Kolkata': 5 * 60 + 30,
  'Europe/London': 0,
  'Europe/Paris': 60,
  'Europe/Berlin': 60,
  'UTC': 0,
  'Etc/UTC': 0,
  'America/New_York': -5 * 60,
  'America/Chicago': -6 * 60,
  'America/Denver': -7 * 60,
  'America/Los_Angeles': -8 * 60,
  'America/Anchorage': -9 * 60,
  'Pacific/Honolulu': -10 * 60,
};
