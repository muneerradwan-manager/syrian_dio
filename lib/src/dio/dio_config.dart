/// Configuration used to initialize [DioNetworkClient].
class DioConfig {
  /// Base URL for all outgoing requests.
  final String baseUrl;

  /// Maximum time to establish a connection.
  final Duration connectTimeout;

  /// Maximum time to receive response data.
  final Duration receiveTimeout;

  /// Asynchronous token provider called before each request.
  final Future<String?> Function()? tokenProvider;

  /// Callback invoked when authentication fails and recovery is not possible.
  final void Function()? onUnauthorized;

  /// Creates Dio-level configuration.
  const DioConfig({
    required this.baseUrl,
    this.connectTimeout = const Duration(seconds: 15),
    this.receiveTimeout = const Duration(seconds: 15),
    this.tokenProvider,
    this.onUnauthorized,
  });
}
