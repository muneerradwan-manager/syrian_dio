import 'package:dio/dio.dart';
import '../core/network_error.dart';
import 'connection_error_classifier.dart';

NetworkError mapDioError(DioException e) {
  final status = e.response?.statusCode;
  final rawMessage = extractRawDioMessage(e);
  final uri = e.requestOptions.uri;
  final host = uri.host.isEmpty ? null : uri.host;

  if (e.type == DioExceptionType.cancel) {
    return NetworkError(
      type: NetworkErrorType.cancelled,
      message: 'Request cancelled',
      cause: e,
      rawMessage: rawMessage,
      host: host,
      uri: uri,
    );
  }

  if (e.type == DioExceptionType.connectionTimeout ||
      e.type == DioExceptionType.sendTimeout ||
      e.type == DioExceptionType.receiveTimeout) {
    return NetworkError(
      type: NetworkErrorType.timeout,
      message: 'Request timeout',
      cause: e,
      rawMessage: rawMessage,
      host: host,
      uri: uri,
    );
  }

  if (status == 401) {
    return NetworkError(
      type: NetworkErrorType.unauthorized,
      message: 'Unauthorized',
      statusCode: status,
      cause: e,
      rawMessage: rawMessage,
      host: host,
      uri: uri,
    );
  }
  if (status == 403) {
    return NetworkError(
      type: NetworkErrorType.forbidden,
      message: 'Forbidden',
      statusCode: status,
      cause: e,
      rawMessage: rawMessage,
      host: host,
      uri: uri,
    );
  }
  if (status == 404) {
    return NetworkError(
      type: NetworkErrorType.notFound,
      message: 'Not found',
      statusCode: status,
      cause: e,
      rawMessage: rawMessage,
      host: host,
      uri: uri,
    );
  }
  if (status != null && status >= 400 && status < 500) {
    return NetworkError(
      type: NetworkErrorType.badResponse,
      message: 'Bad response',
      statusCode: status,
      cause: e,
      rawMessage: rawMessage,
      host: host,
      uri: uri,
    );
  }
  if (status != null && status >= 500) {
    return NetworkError(
      type: NetworkErrorType.server,
      message: 'Server error',
      statusCode: status,
      cause: e,
      rawMessage: rawMessage,
      host: host,
      uri: uri,
    );
  }

  if (e.type == DioExceptionType.connectionError) {
    final failureKind = classifyConnectionFailure(e);
    if (failureKind == ConnectionFailureKind.dnsFailure) {
      return NetworkError(
        type: NetworkErrorType.dnsFailure,
        message: host == null
            ? 'DNS lookup failed'
            : 'DNS lookup failed for host "$host"',
        cause: e,
        rawMessage: rawMessage,
        host: host,
        uri: uri,
      );
    }

    if (failureKind == ConnectionFailureKind.noInternet) {
      return NetworkError(
        type: NetworkErrorType.noInternet,
        message: host == null
            ? 'No internet connection'
            : 'No internet connection while reaching "$host"',
        cause: e,
        rawMessage: rawMessage,
        host: host,
        uri: uri,
      );
    }

    return NetworkError(
      type: NetworkErrorType.unknown,
      message: host == null
          ? 'Connection error: ${rawMessage ?? 'Unspecified connection failure'}'
          : 'Connection error for "$host": ${rawMessage ?? 'Unspecified connection failure'}',
      statusCode: status,
      cause: e,
      rawMessage: rawMessage,
      host: host,
      uri: uri,
    );
  }

  return NetworkError(
    type: NetworkErrorType.unknown,
    message: rawMessage ?? 'Unknown error',
    statusCode: status,
    cause: e,
    rawMessage: rawMessage,
    host: host,
    uri: uri,
  );
}
