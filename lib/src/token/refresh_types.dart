/// Result payload returned by [RefreshCall].
class RefreshResult {
  /// New access token to use for authenticated requests.
  final String accessToken;

  /// Optional rotated refresh token.
  final String? refreshToken;

  /// Creates a refresh token result.
  const RefreshResult({
    required this.accessToken,
    this.refreshToken,
  });
}

/// Signature for app-specific refresh token implementation.
typedef RefreshCall = Future<RefreshResult> Function({
  /// Previously stored refresh token.
  required String refreshToken,
});
