/// Unified error categories produced by the networking layer.
enum NetworkErrorType {
  /// Connection issue or offline state.
  noInternet,

  /// DNS resolution failed (for example invalid hostname).
  dnsFailure,

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

  /// Original low-level message from Dio/Socket when available.
  final String? rawMessage;

  /// Host extracted from the request URI when available.
  final String? host;

  /// Request URI that triggered the error when available.
  final Uri? uri;

  /// Creates a network error.
  const NetworkError({
    required this.type,
    required this.message,
    this.statusCode,
    this.cause,
    this.rawMessage,
    this.host,
    this.uri,
  });

  @override
  String toString() {
    final buffer = StringBuffer('NetworkError($type, $statusCode): $message');
    if (host != null && host!.isNotEmpty) {
      buffer.write(' [host=$host]');
    }
    if (rawMessage != null && rawMessage!.isNotEmpty) {
      buffer.write(' [raw=$rawMessage]');
    }
    return buffer.toString();
  }
}
