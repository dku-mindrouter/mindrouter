const String defaultTimeBucketTimezone = 'Asia/Seoul';

String getTimeBucketByLocalTime({
  required DateTime now,
  required String timezone,
}) {
  final DateTime localTime = _convertToTimezone(now: now, timezone: timezone);
  final int hour = localTime.hour;

  if (hour >= 0 && hour <= 5) {
    return 'dawn';
  }
  if (hour >= 6 && hour <= 10) {
    return 'morning';
  }
  if (hour >= 11 && hour <= 16) {
    return 'day';
  }
  if (hour >= 17 && hour <= 20) {
    return 'evening';
  }
  return 'night';
}

DateTime _convertToTimezone({required DateTime now, required String timezone}) {
  final int targetOffsetMinutes = _resolveOffsetMinutes(timezone);
  final DateTime utc = now.toUtc();
  return utc.add(Duration(minutes: targetOffsetMinutes));
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
