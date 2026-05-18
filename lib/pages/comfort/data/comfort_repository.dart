import '../../../shared/features/data/app_error.dart';
import '../../../shared/features/data/execute_with_error_mapping.dart';
import '../../../shared/features/data/with_retry.dart';
import '../domain/comfort_exception.dart';
import '../domain/comfort_letter.dart';
import '../domain/comfort_notification.dart';
import 'comfort_data_source.dart';

class ComfortRepository {
  ComfortRepository({required ComfortDataSource dataSource})
    : _dataSource = dataSource;

  final ComfortDataSource _dataSource;

  Future<List<ComfortNotification>> fetchComfortNotifications({
    int limit = 30,
    int offset = 0,
  }) async {
    try {
      return await withRetry(
        task: () => executeWithErrorMapping<List<ComfortNotification>>(
          action: () async {
            final dynamic raw = await _dataSource.fetchComfortNotifications(
              limit: limit,
              offset: offset,
            );
            final List<Map<String, dynamic>> rows = _toRows(raw);
            return rows
                .map(ComfortNotification.fromMap)
                .toList(growable: false);
          },
        ),
        maxRetryCount: 2,
        shouldRetry: _shouldRetry,
      );
    } catch (error) {
      throw mapToComfortException(error);
    }
  }

  Future<ComfortLetter> openLetter({required String letterId}) async {
    try {
      return await withRetry(
        task: () => executeWithErrorMapping<ComfortLetter>(
          action: () async {
            final dynamic raw = await _dataSource.openLetter(
              letterId: letterId,
            );
            final Map<String, dynamic> row = _firstRow(raw);
            return ComfortLetter.fromMap(row);
          },
        ),
        maxRetryCount: 2,
        shouldRetry: _shouldRetry,
      );
    } catch (error) {
      throw mapToComfortException(error);
    }
  }

  ComfortException mapToComfortException(Object error) {
    if (error is MappedAppException) {
      return ComfortException(error.code, message: error.message);
    }
    if (error is ComfortException) {
      return error;
    }
    return ComfortException(
      ComfortErrorCode.internalError,
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
        error.code == ComfortErrorCode.internalError;
  }
}
