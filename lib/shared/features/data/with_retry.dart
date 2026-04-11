import 'dart:async';

Future<T> withRetry<T>({
  required Future<T> Function() task,
  int maxRetryCount = 2,
  Duration delay = const Duration(milliseconds: 80),
  bool Function(Object error)? shouldRetry,
}) async {
  int attempt = 0;
  while (true) {
    try {
      return await task();
    } catch (error) {
      attempt += 1;
      final bool canRetry = shouldRetry?.call(error) ?? true;
      if (!canRetry || attempt > maxRetryCount) {
        rethrow;
      }
      await Future<void>.delayed(delay);
    }
  }
}
