import 'app_error.dart';
import 'error_mapping.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

Future<T> executeRpcWithErrorMapping<T>({
  required String rpcName,
  required Map<String, dynamic> params,
  required T Function(dynamic raw) mapper,
}) async {
  try {
    final dynamic raw = await Supabase.instance.client.rpc(
      rpcName,
      params: params,
    );
    return mapper(raw);
  } catch (error) {
    throw MappedAppException(
      code: parsePostgrestErrorCode(error: error),
      message: error.toString(),
      originalError: error,
    );
  }
}

Future<T> executeWithErrorMapping<T>({
  required Future<T> Function() action,
}) async {
  try {
    return await action();
  } catch (error) {
    throw MappedAppException(
      code: parsePostgrestErrorCode(error: error),
      message: error.toString(),
      originalError: error,
    );
  }
}
