import '../../../shared/features/data/app_error.dart';
import '../../../shared/features/data/execute_with_error_mapping.dart';
import '../../../shared/features/data/with_retry.dart';
import '../domain/avatar_collection_item.dart';
import '../domain/my_stats.dart';
import '../domain/my_star_history_item.dart';
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
              avatarNameKo: row['avatar_name_ko'] as String? ?? '달토끼',
              avatarLevel: (row['avatar_level'] as num?)?.toInt() ?? 1,
              avatarXp: (row['avatar_xp'] as num?)?.toInt() ?? 0,
              avatarLevelTitleKo:
                  row['avatar_level_title_ko'] as String? ?? '처음 만난 마음',
              avatarCurrentLevelXp:
                  (row['avatar_current_level_xp'] as num?)?.toInt() ?? 0,
              avatarNextLevelXp:
                  (row['avatar_next_level_xp'] as num?)?.toInt() ?? 80,
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

  Future<List<MyStarHistoryItem>> fetchMyStars({
    int limit = 30,
    int offset = 0,
  }) async {
    try {
      return await withRetry(
        task: () => executeWithErrorMapping<List<MyStarHistoryItem>>(
          action: () async {
            final dynamic raw = await _dataSource.fetchMyStars(
              limit: limit,
              offset: offset,
            );
            return _toRows(
              raw,
            ).map(MyStarHistoryItem.fromMap).toList(growable: false);
          },
        ),
        maxRetryCount: 2,
        shouldRetry: _shouldRetry,
      );
    } catch (error) {
      throw mapToProfileException(error);
    }
  }

  Future<List<AvatarCollectionItem>> fetchAvatarCollection() async {
    try {
      return await withRetry(
        task: () => executeWithErrorMapping<List<AvatarCollectionItem>>(
          action: () async {
            final dynamic raw = await _dataSource.fetchAvatarCollection();
            return _toRows(
              raw,
            ).map(AvatarCollectionItem.fromMap).toList(growable: false);
          },
        ),
        maxRetryCount: 2,
        shouldRetry: _shouldRetry,
      );
    } catch (error) {
      throw mapToProfileException(error);
    }
  }

  Future<void> equipAvatar({required String userAvatarId}) async {
    try {
      await executeWithErrorMapping<void>(
        action: () async {
          await _dataSource.equipAvatar(userAvatarId: userAvatarId);
        },
      );
    } catch (error) {
      throw mapToProfileException(error);
    }
  }

  Future<String> updateNickname({required String nickname}) async {
    try {
      return await executeWithErrorMapping<String>(
        action: () async {
          final dynamic raw = await _dataSource.updateNickname(
            nickname: nickname,
          );
          final Map<String, dynamic> row = _firstRow(raw);
          return row['nickname'] as String? ?? nickname.trim();
        },
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
    final List<Map<String, dynamic>> rows = _toRows(raw);
    if (rows.isNotEmpty) {
      return rows.first;
    }
    throw const FormatException('Unexpected RPC response shape');
  }

  List<Map<String, dynamic>> _toRows(dynamic raw) {
    if (raw is List) {
      return raw
          .whereType<Map>()
          .map((Map row) => Map<String, dynamic>.from(row))
          .toList(growable: false);
    }
    if (raw is Map) {
      return <Map<String, dynamic>>[Map<String, dynamic>.from(raw)];
    }
    return const <Map<String, dynamic>>[];
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
