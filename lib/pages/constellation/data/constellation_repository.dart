import '../../../shared/features/data/app_error.dart';
import '../../../shared/features/data/execute_with_error_mapping.dart';
import '../../../shared/features/data/with_retry.dart';
import '../domain/constellation_exception.dart';
import '../domain/feed_filter.dart';
import '../domain/today_status.dart';
import '../domain/star.dart';
import 'constellation_data_source.dart';

class ConstellationRepository {
  ConstellationRepository({required ConstellationDataSource dataSource})
    : _dataSource = dataSource;

  final ConstellationDataSource _dataSource;

  Future<List<Star>> fetchFeed({
    String filterName = 'all',
    int limit = 20,
    int offset = 0,
  }) async {
    final int adjustedLimit = limit.clamp(1, 50).toInt();
    final int adjustedOffset = offset < 0 ? 0 : offset;
    final FeedFilter parsedFilter = parseFeedFilter(filterName);

    try {
      return await withRetry(
        task: () => executeWithErrorMapping<List<Star>>(
          action: () async {
            final dynamic raw = await _dataSource.fetchFeed(
              filterName: feedFilterToName(parsedFilter),
              limit: adjustedLimit,
              offset: adjustedOffset,
            );
            final List<Map<String, dynamic>> rows = _toRows(raw);
            return rows.map(Star.fromFeedMap).toList(growable: false);
          },
        ),
        maxRetryCount: 2,
        shouldRetry: _shouldRetry,
      );
    } catch (error) {
      throw mapToConstellationException(error);
    }
  }

  Future<Star> fetchStarById(String starId) async {
    try {
      return await withRetry(
        task: () => executeWithErrorMapping<Star>(
          action: () async {
            final dynamic raw = await _dataSource.fetchStarDetail(
              starId: starId,
            );
            final Map<String, dynamic> row = _firstRow(raw);
            return Star.fromDetailMap(row);
          },
        ),
        maxRetryCount: 2,
        shouldRetry: _shouldRetry,
      );
    } catch (error) {
      throw mapToConstellationException(error);
    }
  }

  Future<void> markStarSeen({
    required String starId,
    required String userId,
  }) async {
    try {
      await withRetry(
        task: () => executeWithErrorMapping<void>(
          action: () =>
              _dataSource.markStarSeen(starId: starId, userId: userId),
        ),
        maxRetryCount: 2,
        shouldRetry: _shouldRetry,
      );
    } catch (error) {
      throw mapToConstellationException(error);
    }
  }

  Future<TodayStatus> fetchTodayStatus() async {
    try {
      return await withRetry(
        task: () => executeWithErrorMapping<TodayStatus>(
          action: () async {
            final dynamic raw = await _dataSource.fetchTodayStatus();
            return TodayStatus.fromMap(_firstRow(raw));
          },
        ),
        maxRetryCount: 2,
        shouldRetry: _shouldRetry,
      );
    } catch (error) {
      throw mapToConstellationException(error);
    }
  }

  ConstellationException mapToConstellationException(Object error) {
    if (error is MappedAppException) {
      return ConstellationException(error.code, message: error.message);
    }
    if (error is ConstellationException) {
      return error;
    }
    return ConstellationException(
      ConstellationErrorCode.internalError,
      message: error.toString(),
    );
  }

  List<Map<String, dynamic>> _toRows(dynamic raw) {
    if (raw is List) {
      return raw.whereType<Map<String, dynamic>>().toList(growable: false);
    }
    if (raw is Map<String, dynamic>) {
      return <Map<String, dynamic>>[raw];
    }
    return const <Map<String, dynamic>>[];
  }

  Map<String, dynamic> _firstRow(dynamic raw) {
    final List<Map<String, dynamic>> rows = _toRows(raw);
    if (rows.isNotEmpty) {
      return rows.first;
    }
    throw const FormatException('Unexpected RPC response shape');
  }

  bool _shouldRetry(Object error) {
    return error is MappedAppException &&
        error.code == ConstellationErrorCode.internalError;
  }
}
