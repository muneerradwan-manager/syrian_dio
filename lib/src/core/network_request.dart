import 'http_method.dart';

class NetworkRequest {
  final HttpMethod method;
  final String path;
  final Map<String, dynamic>? query;
  final dynamic body;
  final Map<String, String>? headers;

  const NetworkRequest({
    required this.method,
    required this.path,
    this.query,
    this.body,
    this.headers,
  });
}
