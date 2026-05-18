import '../../../shared/features/data/app_error.dart';
import '../../../shared/features/data/execute_with_error_mapping.dart';
import '../../../shared/features/data/with_retry.dart';
import '../domain/my_stats.dart';
import '../domain/profile_exception.dart';
import '../domain/profile_policies.dart';
import 'profile_data_source.dart';

class ProfileRepository {
  ProfileRepository({required ProfileDataSource dataSource})
    : _dataSource = dataSource;

  final ProfileDataSource _dataSource;

  Future<MyStats> fetchMyStats() async {
    try {
      return await withRetry(
        task: () => executeWithErrorMapping<MyStats>(
          action: () async {
            final dynamic raw = await _dataSource.fetchMyStats();
            final Map<String, dynamic> row = _firstRow(raw);
            final DateTime dateLocal = _asDateTime(row['date_local']);
            final List<DateTime> loggedDates = _asDateList(row['logged_dates']);
            final MyStats stats = MyStats(
              dateLocal: dateLocal,
              currentStreak: calculateStreak(
                logs: loggedDates,
                todayLocal: dateLocal,
              ),
              todayReceivedComfortCount:
                  (row['today_received_comfort_count'] as num?)?.toInt() ?? 0,
            );
            await checkStatsConsistency(stats: stats);
            return stats;
          },
        ),
        maxRetryCount: 2,
        shouldRetry: _shouldRetry,
      );
    } catch (error) {
      throw mapToProfileException(error);
    }
  }

  ProfileException mapToProfileException(Object error) {
    if (error is MappedAppException) {
      return ProfileException(error.code, message: error.message);
    }
    if (error is ProfileException) {
      return error;
    }
    return ProfileException(
      ProfileErrorCode.internalError,
      message: error.toString(),
    );
  }

  Map<String, dynamic> _firstRow(dynamic raw) {
    if (raw is List && raw.isNotEmpty && raw.first is Map<String, dynamic>) {
      return raw.first as Map<String, dynamic>;
    }
    if (raw is Map<String, dynamic>) {
      return raw;
    }
    throw const FormatException('Unexpected RPC response shape');
  }

  DateTime _asDateTime(dynamic value) {
    if (value is DateTime) {
      return value;
    }
    if (value is String && value.isNotEmpty) {
      return DateTime.parse(value);
    }
    throw const FormatException('Invalid date_local value');
  }

  List<DateTime> _asDateList(dynamic value) {
    if (value is! List) {
      return const <DateTime>[];
    }
    return value
        .map<DateTime?>((dynamic item) {
          if (item is DateTime) {
            return item;
          }
          if (item is String && item.isNotEmpty) {
            return DateTime.parse(item);
          }
          return null;
        })
        .whereType<DateTime>()
        .toList(growable: false);
  }

  bool _shouldRetry(Object error) {
    return error is MappedAppException &&
        error.code == ProfileErrorCode.internalError;
  }
}
