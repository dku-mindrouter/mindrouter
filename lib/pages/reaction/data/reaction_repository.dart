import 'dart:async';

import '../../../shared/features/data/app_error.dart';
import '../../../shared/features/data/execute_with_error_mapping.dart';
import '../../../shared/features/data/with_retry.dart';
import '../domain/daily_quota.dart';
import '../domain/reaction_exception.dart';
import '../domain/reaction_type.dart';
import '../domain/send_reaction_result.dart';
import 'reaction_data_source.dart';

class ReactionRepository {
  ReactionRepository({required ReactionDataSource dataSource})
    : _dataSource = dataSource;

  final ReactionDataSource _dataSource;

  Future<List<ReactionType>> fetchReactionTypes() async {
    try {
      return await withRetry(
        task: () => executeWithErrorMapping<List<ReactionType>>(
          action: () async {
            final List<Map<String, dynamic>> rows = await _dataSource
                .fetchReactionTypes();
            return rows.map(ReactionType.fromMap).toList(growable: false);
          },
        ),
        maxRetryCount: 2,
        shouldRetry: _shouldRetry,
      );
    } catch (error) {
      throw mapToReactionException(error);
    }
  }

  Future<SendReactionResult> sendReaction({
    required String starId,
    required int reactionTypeId,
  }) async {
    try {
      final SendReactionResult result = await withRetry(
        task: () => executeWithErrorMapping<SendReactionResult>(
          action: () async {
            final dynamic raw = await _dataSource.sendReaction(
              starId: starId,
              reactionTypeId: reactionTypeId,
            );
            final Map<String, dynamic> row = _firstRow(raw);
            return SendReactionResult.fromMap(row);
          },
        ),
        maxRetryCount: 2,
        shouldRetry: _shouldRetry,
      );
      unawaited(_notifyReactionPush(reactionId: result.reactionId));
      return result;
    } catch (error) {
      throw mapToReactionException(error);
    }
  }

  Future<DailyQuota> fetchReactionQuota() async {
    try {
      return await withRetry(
        task: () => executeWithErrorMapping<DailyQuota>(
          action: () async {
            final dynamic raw = await _dataSource.fetchReactionQuota();
            final Map<String, dynamic> row = _firstRow(raw);
            return DailyQuota.fromMap(row);
          },
        ),
        maxRetryCount: 2,
        shouldRetry: _shouldRetry,
      );
    } catch (error) {
      throw mapToReactionException(error);
    }
  }

  ReactionException mapToReactionException(Object error) {
    if (error is MappedAppException) {
      return ReactionException(error.code, message: error.message);
    }
    if (error is ReactionException) {
      return error;
    }
    return ReactionException(
      ReactionErrorCode.internalError,
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

  bool _shouldRetry(Object error) {
    return error is MappedAppException &&
        error.code == ReactionErrorCode.internalError;
  }

  Future<void> _notifyReactionPush({required String reactionId}) async {
    try {
      await _dataSource.notifyReactionPush(reactionId: reactionId);
    } catch (_) {
      // Push delivery is best-effort and must not roll back reaction success.
    }
  }
}
