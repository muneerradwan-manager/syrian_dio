abstract class TokenStore {
  Future<String?> getAccessToken();
  Future<String?> getRefreshToken();

  Future<void> saveAccessToken(String token);
  Future<void> saveRefreshToken(String token);

  Future<void> clear();
}
