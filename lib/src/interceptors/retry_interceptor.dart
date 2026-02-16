import 'dart:math';
import 'package:dio/dio.dart';

/// Retries transient failures using exponential backoff with jitter.
class RetryInterceptor extends Interceptor {
  /// Dio instance used to re-dispatch failed requests.
  final Dio dio;

  /// Maximum retry attempts per request.
  final int maxRetries;

  /// Initial backoff delay.
  final Duration baseDelay;

  /// Creates a retry interceptor.
  RetryInterceptor({
    required this.dio,
    this.maxRetries = 3,
    this.baseDelay = const Duration(milliseconds: 400),
  });

  bool _shouldRetry(DioException err) {
    if (err.type == DioExceptionType.connectionError ||
        err.type == DioExceptionType.connectionTimeout ||
        err.type == DioExceptionType.receiveTimeout ||
        err.type == DioExceptionType.sendTimeout) {
      return true;
    }
    final status = err.response?.statusCode ?? 0;
    return status >= 500;
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) async {
    final retries = (err.requestOptions.extra['retries'] as int?) ?? 0;

    if (!_shouldRetry(err) || retries >= maxRetries) {
      return handler.next(err);
    }

    err.requestOptions.extra['retries'] = retries + 1;

    final delay = _exponentialDelay(retries + 1);
    await Future.delayed(delay);

    try {
      final response = await dio.fetch(err.requestOptions);
      return handler.resolve(response);
    } on DioException catch (e) {
      return handler.next(e);
    }
  }

  Duration _exponentialDelay(int attempt) {
    final rnd = Random();
    final ms = baseDelay.inMilliseconds * pow(2, attempt);
    final jitter = rnd.nextInt(250);
    return Duration(milliseconds: ms.toInt() + jitter);
  }
}
