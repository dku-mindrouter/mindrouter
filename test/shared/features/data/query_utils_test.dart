import 'package:flutter_test/flutter_test.dart';
import 'package:mindfulconnect/shared/features/data/query_utils.dart';

void main() {
  group('buildPaginationParams', () {
    test('builds params with normalized minimum values', () {
      final Map<String, dynamic> params = buildPaginationParams(
        limit: 0,
        offset: -1,
      );

      expect(params, <String, dynamic>{'p_limit': 1, 'p_offset': 0});
    });
  });

  group('mapUtcToUserTimezone', () {
    test('maps utc to timezone with fallback', () {
      final DateTime utcTime = DateTime.utc(2026, 1, 1, 0, 0);
      final DateTime local = mapUtcToUserTimezone(
        utcTime: utcTime,
        timezone: 'Asia/Seoul',
      );
      final DateTime fallbackLocal = mapUtcToUserTimezone(
        utcTime: utcTime,
        timezone: 'Unknown/Zone',
      );

      expect(local.hour, 9);
      expect(fallbackLocal.hour, 9);
    });
  });
}
