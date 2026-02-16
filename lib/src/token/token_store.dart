/// Storage contract for access and refresh tokens.
abstract class TokenStore {
  /// Returns current access token or `null` when unavailable.
  Future<String?> getAccessToken();

  /// Returns current refresh token or `null` when unavailable.
  Future<String?> getRefreshToken();

  /// Persists a new access token.
  Future<void> saveAccessToken(String token);

  /// Persists a new refresh token.
  Future<void> saveRefreshToken(String token);

  /// Clears all stored tokens.
  Future<void> clear();
}
