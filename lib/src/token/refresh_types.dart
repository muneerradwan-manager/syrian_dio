class RefreshResult {
  final String accessToken;
  final String? refreshToken;

  const RefreshResult({
    required this.accessToken,
    this.refreshToken,
  });
}

typedef RefreshCall = Future<RefreshResult> Function({
  required String refreshToken,
});
