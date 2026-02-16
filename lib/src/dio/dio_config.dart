class DioConfig {
  final String baseUrl;
  final Duration connectTimeout;
  final Duration receiveTimeout;

  /// token وقت الطلب (ديناميكي)
  final Future<String?> Function()? tokenProvider;

  /// callback إذا فشل refresh أو صار unauthorized نهائي
  final void Function()? onUnauthorized;

  const DioConfig({
    required this.baseUrl,
    this.connectTimeout = const Duration(seconds: 15),
    this.receiveTimeout = const Duration(seconds: 15),
    this.tokenProvider,
    this.onUnauthorized,
  });
}
