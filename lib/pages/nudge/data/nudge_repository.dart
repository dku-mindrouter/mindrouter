import '../../../shared/features/data/app_error.dart';
import '../../../shared/features/data/execute_with_error_mapping.dart';
import '../../../shared/features/data/with_retry.dart';
import '../domain/nudge_exception.dart';
import '../domain/nudge_mission.dart';
import 'nudge_data_source.dart';

class NudgeRepository {
  NudgeRepository({required NudgeDataSource dataSource})
    : _dataSource = dataSource;

  final NudgeDataSource _dataSource;

  Future<NudgeMission> fetchTodayMission({
    bool markOpened = false,
    String? selectedEmotionProfile,
  }) async {
    try {
      return await withRetry(
        task: () => executeWithErrorMapping<NudgeMission>(
          action: () async {
            final dynamic raw = await _dataSource.fetchTodayMission(
              markOpened: markOpened,
              selectedEmotionProfile: selectedEmotionProfile,
            );
            return NudgeMission.fromMap(_firstRow(raw));
          },
        ),
        maxRetryCount: 2,
        shouldRetry: _shouldRetry,
      );
    } catch (error) {
      throw mapToNudgeException(error);
    }
  }

  Future<void> startTodayMission({required String deliveryId}) async {
    try {
      await withRetry(
        task: () => executeWithErrorMapping<void>(
          action: () => _dataSource.startTodayMission(deliveryId: deliveryId),
        ),
        maxRetryCount: 1,
        shouldRetry: _shouldRetry,
      );
    } catch (error) {
      throw mapToNudgeException(error);
    }
  }

  Future<void> completeTodayMission({required String deliveryId}) async {
    try {
      await withRetry(
        task: () => executeWithErrorMapping<void>(
          action: () =>
              _dataSource.completeTodayMission(deliveryId: deliveryId),
        ),
        maxRetryCount: 1,
        shouldRetry: _shouldRetry,
      );
    } catch (error) {
      throw mapToNudgeException(error);
    }
  }

  NudgeException mapToNudgeException(Object error) {
    if (error is MappedAppException) {
      return NudgeException(error.code, message: error.message);
    }
    if (error is NudgeException) {
      return error;
    }
    return NudgeException(
      NudgeErrorCode.internalError,
      message: error.toString(),
    );
  }

  Map<String, dynamic> _firstRow(dynamic raw) {
    if (raw is List && raw.isNotEmpty && raw.first is Map) {
      return Map<String, dynamic>.from(raw.first as Map);
    }
    if (raw is Map) {
      return Map<String, dynamic>.from(raw);
    }
    throw const FormatException('Unexpected RPC response shape');
  }

  bool _shouldRetry(Object error) {
    return error is MappedAppException &&
        error.code == NudgeErrorCode.internalError;
  }
}
