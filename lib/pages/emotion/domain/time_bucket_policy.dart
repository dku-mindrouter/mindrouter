import '../../../shared/features/time_bucket.dart' as shared_time_bucket;

const String defaultEmotionTimezone = shared_time_bucket.defaultTimeBucketTimezone;

String getTimeBucketByLocalTime({
  required DateTime now,
  required String timezone,
}) {
  return shared_time_bucket.getTimeBucketByLocalTime(
    now: now,
    timezone: timezone,
  );
}
