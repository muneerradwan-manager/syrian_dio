enum NetworkErrorType {
  noInternet,
  timeout,
  cancelled,
  unauthorized,
  forbidden,
  notFound,
  badResponse,
  server,
  unknown,
}

class NetworkError {
  final NetworkErrorType type;
  final String message;
  final int? statusCode;
  final Object? cause;

  const NetworkError({
    required this.type,
    required this.message,
    this.statusCode,
    this.cause,
  });

  @override
  String toString() => 'NetworkError($type, $statusCode): $message';
}
