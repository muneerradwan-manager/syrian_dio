/// Unified error categories produced by the networking layer.
enum NetworkErrorType {
  /// Connection issue or offline state.
  noInternet,

  /// Timeout in connect/send/receive phases.
  timeout,

  /// Request was cancelled by caller.
  cancelled,

  /// Authentication failed (401).
  unauthorized,

  /// Authorization failed (403).
  forbidden,

  /// Resource was not found (404).
  notFound,

  /// Other 4xx response.
  badResponse,

  /// 5xx response.
  server,

  /// Any unmapped or unexpected failure.
  unknown,
}

/// Domain error wrapper used by [Result].
class NetworkError {
  /// Error category.
  final NetworkErrorType type;

  /// Human-readable error message.
  final String message;

  /// HTTP status code when available.
  final int? statusCode;

  /// Optional original error object.
  final Object? cause;

  /// Creates a network error.
  const NetworkError({
    required this.type,
    required this.message,
    this.statusCode,
    this.cause,
  });

  @override
  String toString() => 'NetworkError($type, $statusCode): $message';
}
