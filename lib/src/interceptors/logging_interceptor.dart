import 'package:dio/dio.dart';

class LoggingInterceptor extends Interceptor {
  final bool logBody;
  LoggingInterceptor({this.logBody = false});

  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    // ignore: avoid_print
    print('[REQ] ${options.method} ${options.uri}');
    handler.next(options);
  }

  @override
  void onResponse(Response response, ResponseInterceptorHandler handler) {
    // ignore: avoid_print
    print('[RES] ${response.statusCode} ${response.requestOptions.uri}');
    if (logBody) {
      // ignore: avoid_print
      print(response.data);
    }
    handler.next(response);
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    // ignore: avoid_print
    print('[ERR] ${err.type} ${err.requestOptions.uri} -> ${err.message}');
    handler.next(err);
  }
}
