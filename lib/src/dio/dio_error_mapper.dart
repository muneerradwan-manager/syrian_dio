import 'package:dio/dio.dart';
import '../core/network_error.dart';

NetworkError mapDioError(DioException e) {
  if (e.type == DioExceptionType.cancel) {
    return NetworkError(type: NetworkErrorType.cancelled, message: 'Request cancelled', cause: e);
  }

  if (e.type == DioExceptionType.connectionTimeout ||
      e.type == DioExceptionType.sendTimeout ||
      e.type == DioExceptionType.receiveTimeout) {
    return NetworkError(type: NetworkErrorType.timeout, message: 'Request timeout', cause: e);
  }

  final status = e.response?.statusCode;

  if (status == 401) {
    return NetworkError(type: NetworkErrorType.unauthorized, message: 'Unauthorized', statusCode: status, cause: e);
  }
  if (status == 403) {
    return NetworkError(type: NetworkErrorType.forbidden, message: 'Forbidden', statusCode: status, cause: e);
  }
  if (status == 404) {
    return NetworkError(type: NetworkErrorType.notFound, message: 'Not found', statusCode: status, cause: e);
  }
  if (status != null && status >= 400 && status < 500) {
    return NetworkError(type: NetworkErrorType.badResponse, message: 'Bad response', statusCode: status, cause: e);
  }
  if (status != null && status >= 500) {
    return NetworkError(type: NetworkErrorType.server, message: 'Server error', statusCode: status, cause: e);
  }

  if (e.type == DioExceptionType.connectionError) {
    return NetworkError(type: NetworkErrorType.noInternet, message: 'No internet connection', cause: e);
  }

  return NetworkError(
    type: NetworkErrorType.unknown,
    message: e.message ?? 'Unknown error',
    statusCode: status,
    cause: e,
  );
}
