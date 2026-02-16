import 'package:dio/dio.dart';
import '../dio/dio_config.dart';

class AuthInterceptor extends Interceptor {
  final DioConfig config;
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
