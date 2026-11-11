import 'package:dio/dio.dart';

/// Retries transient failures (connection problems, timeouts, 5xx) with exponential backoff.
class RetryInterceptor extends Interceptor {
  RetryInterceptor({
    required this._dio,
    this.maxAttempts = 3,
    this.baseDelay = const Duration(milliseconds: 500),
  });

  static const _attemptKey = 'retry_attempt';

  final Dio _dio;
  final int maxAttempts;
  final Duration baseDelay;

  @override
  Future<void> onError(
    DioException err,
    ErrorInterceptorHandler handler,
  ) async {
    final attempt = err.requestOptions.extra[_attemptKey] as int? ?? 1;
    if (attempt >= maxAttempts || !isTransient(err)) {
      handler.next(err);
      return;
    }
    await Future<void>.delayed(baseDelay * (1 << (attempt - 1)));
    final options = err.requestOptions..extra[_attemptKey] = attempt + 1;
    try {
      handler.resolve(await _dio.fetch<dynamic>(options));
    } on DioException catch (e) {
      handler.next(e);
    }
  }

  static bool isTransient(DioException e) {
    return switch (e.type) {
      DioExceptionType.connectionError ||
      DioExceptionType.connectionTimeout ||
      DioExceptionType.sendTimeout ||
      DioExceptionType.receiveTimeout => true,
      _ => (e.response?.statusCode ?? 0) >= 500,
    };
  }
}
