import 'package:dio/dio.dart';
import '../core/network_client.dart';
import '../core/network_request.dart';
import '../core/http_method.dart';
import '../core/result.dart';
import '../core/network_error.dart';
import 'dio_config.dart';
import 'dio_error_mapper.dart';
import '../interceptors/auth_interceptor.dart';
import '../interceptors/logging_interceptor.dart';
import '../interceptors/retry_interceptor.dart';
import '../interceptors/refresh_token_interceptor.dart';
import '../token/token_store.dart';
import '../token/refresh_types.dart';

class DioNetworkClient extends NetworkClient {
  final Dio _dio;
  final DioConfig _config;

  DioNetworkClient._(this._dio, this._config);

  factory DioNetworkClient({
    required DioConfig config,
    Dio? dio,
    bool enableLogging = true,
    bool logBody = false,
    bool enableRetry = true,
    int maxRetries = 3,
    bool enableRefreshToken = false,
    TokenStore? tokenStore,
    RefreshCall? refreshCall,
    void Function()? onRefreshFailed,
    String refreshPathContains = '/auth/refresh',
    List<Interceptor> extraInterceptors = const [],
  }) {
    final d =
        dio ??
        Dio(
          BaseOptions(
            baseUrl: config.baseUrl,
            connectTimeout: config.connectTimeout,
            receiveTimeout: config.receiveTimeout,
          ),
        );

    // Retry أولاً
    if (enableRetry) {
      d.interceptors.add(RetryInterceptor(dio: d, maxRetries: maxRetries));
    }

    // Auth header
    d.interceptors.add(AuthInterceptor(config));

    // Refresh token (اختياري)
    if (enableRefreshToken) {
      if (tokenStore == null || refreshCall == null) {
        throw ArgumentError(
          'tokenStore and refreshCall are required when enableRefreshToken=true',
        );
      }
      d.interceptors.add(
        RefreshTokenInterceptor(
          dio: d,
          tokenStore: tokenStore,
          refreshCall: refreshCall,
          onRefreshFailed: onRefreshFailed ?? config.onUnauthorized,
          refreshPathContains: refreshPathContains,
        ),
      );
    }

    // Logging
    if (enableLogging) {
      d.interceptors.add(LoggingInterceptor(logBody: logBody));
    }

    // Extra
    d.interceptors.addAll(extraInterceptors);

    return DioNetworkClient._(d, config);
  }

  @override
  Future<Result<T>> send<T>({
    required NetworkRequest request,
    required T Function(dynamic raw) parser,
  }) async {
    try {
      final res = await _dio.request(
        request.path,
        data: request.body,
        queryParameters: request.query,
        options: Options(
          method: _toDioMethod(request.method),
          headers: request.headers,
        ),
      );

      final parsed = parser(res.data);
      return Ok(parsed);
    } on DioException catch (e) {
      final err = mapDioError(e);

      // إذا unauthorized نهائي (وما في refresh شغال/أو فشل) المستخدم يقرر
      if (err.type == NetworkErrorType.unauthorized) {
        _config.onUnauthorized?.call();
      }

      return Err(err);
    } catch (e) {
      return Err(
        NetworkError(
          type: NetworkErrorType.unknown,
          message: e.toString(),
          cause: e,
        ),
      );
    }
  }

  String _toDioMethod(HttpMethod m) {
    switch (m) {
      case HttpMethod.get:
        return 'GET';
      case HttpMethod.post:
        return 'POST';
      case HttpMethod.put:
        return 'PUT';
      case HttpMethod.patch:
        return 'PATCH';
      case HttpMethod.delete:
        return 'DELETE';
    }
  }
}
