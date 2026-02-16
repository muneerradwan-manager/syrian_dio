import 'package:dio/dio.dart';
import '../dio/dio_config.dart';

/// Injects bearer token from [DioConfig.tokenProvider] into outgoing requests.
class AuthInterceptor extends Interceptor {
  /// Runtime Dio configuration.
  final DioConfig config;

  /// Creates an auth interceptor.
  AuthInterceptor(this.config);

  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) async {
    final token = await config.tokenProvider?.call();
    if (token != null && token.isNotEmpty) {
      options.headers['Authorization'] = 'Bearer $token';
    }
    handler.next(options);
  }
}
