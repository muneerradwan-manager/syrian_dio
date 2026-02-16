import 'http_method.dart';

/// Immutable request description consumed by [NetworkClient.send].
class NetworkRequest {
  /// HTTP verb.
  final HttpMethod method;

  /// Relative path that will be resolved against the configured base URL.
  final String path;

  /// Optional query parameters.
  final Map<String, dynamic>? query;

  /// Optional request body.
  final dynamic body;

  /// Optional request headers for this call.
  final Map<String, String>? headers;

  /// Creates a network request payload.
  const NetworkRequest({
    required this.method,
    required this.path,
    this.query,
    this.body,
    this.headers,
  });
}
