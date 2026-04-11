import '../../../shared/features/data/app_error.dart';
import '../../../shared/features/data/execute_with_error_mapping.dart';
import '../../../shared/features/data/with_retry.dart';
import '../domain/create_star_result.dart';
import '../domain/emotion_exception.dart';
import '../domain/emotion_tag.dart';
import '../domain/today_star_status.dart';
import 'emotion_data_source.dart';

class EmotionRepository {
  EmotionRepository({required EmotionDataSource dataSource})
    : _dataSource = dataSource;

  final EmotionDataSource _dataSource;

  Future<List<EmotionTag>> fetchEmotionTags() async {
    return withRetry(
      task: () => executeWithErrorMapping<List<EmotionTag>>(
        action: () async {
          final List<Map<String, dynamic>> rawTags = await _dataSource
              .fetchEmotionTags();
          return rawTags.map(EmotionTag.fromMap).toList(growable: false);
        },
      ),
      maxRetryCount: 2,
      shouldRetry: (Object error) =>
          error is MappedAppException &&
          error.code == EmotionErrorCode.internalError,
    );
  }

  Future<CreateStarResult> createStar({
    required String content,
    required List<int> tagIds,
    required String timeBucket,
    required String visibilityStatus,
    int? emotionIntensity,
    DateTime? expiresAt,
  }) async {
    return withRetry(
      task: () => executeWithErrorMapping<CreateStarResult>(
        action: () async {
          final dynamic raw = await _dataSource.createStar(
            content: content,
            tagIds: tagIds,
            timeBucket: timeBucket,
            visibilityStatus: visibilityStatus,
            emotionIntensity: emotionIntensity,
            expiresAt: expiresAt,
          );
          final Map<String, dynamic> row = _firstRow(raw);
          return CreateStarResult.fromMap(row);
        },
      ),
      maxRetryCount: 2,
      shouldRetry: (Object error) =>
          error is MappedAppException &&
          error.code == EmotionErrorCode.internalError,
    );
  }

  Future<TodayStarStatus> fetchTodayStarStatus() async {
    return withRetry(
      task: () => executeWithErrorMapping<TodayStarStatus>(
        action: () async {
          final dynamic raw = await _dataSource.fetchTodayStarStatus();
          final Map<String, dynamic> row = _firstRow(raw);
          return TodayStarStatus.fromMap(row);
        },
      ),
      maxRetryCount: 2,
      shouldRetry: (Object error) =>
          error is MappedAppException &&
          error.code == EmotionErrorCode.internalError,
    );
  }

  EmotionException mapToEmotionException(Object error) {
    if (error is MappedAppException) {
      return EmotionException(error.code, message: error.message);
    }
    if (error is EmotionException) {
      return error;
    }
    return EmotionException(
      EmotionErrorCode.internalError,
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
}
