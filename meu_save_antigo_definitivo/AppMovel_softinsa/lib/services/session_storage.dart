import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class SessionTokens {
  final String accessToken;
  final String refreshToken;

  const SessionTokens({
    required this.accessToken,
    required this.refreshToken,
  });
}

class SessionStorageException implements Exception {
  final String message;

  const SessionStorageException(this.message);

  @override
  String toString() => message;
}

class SessionStorage {
  SessionStorage._();

  static final SessionStorage instance = SessionStorage._();

  static const String _accessTokenKey = 'auth_access_token';
  static const String _refreshTokenKey = 'auth_refresh_token';

  final FlutterSecureStorage _storage = const FlutterSecureStorage();

  Future<void> saveTokens({
    required String accessToken,
    required String refreshToken,
  }) async {
    final cleanAccessToken = accessToken.trim();
    final cleanRefreshToken = refreshToken.trim();

    if (cleanAccessToken.isEmpty || cleanRefreshToken.isEmpty) {
      throw const SessionStorageException('invalid_tokens');
    }

    try {
      await _storage.write(key: _accessTokenKey, value: cleanAccessToken);
      await _storage.write(key: _refreshTokenKey, value: cleanRefreshToken);
    } catch (_) {
      await _clearTokensSilently();
      throw const SessionStorageException('save_failed');
    }
  }

  Future<SessionTokens?> readTokens() async {
    try {
      final accessToken = await _storage.read(key: _accessTokenKey);
      final refreshToken = await _storage.read(key: _refreshTokenKey);
      final hasAccessToken =
          accessToken != null && accessToken.trim().isNotEmpty;
      final hasRefreshToken =
          refreshToken != null && refreshToken.trim().isNotEmpty;

      if (hasAccessToken && hasRefreshToken) {
        return SessionTokens(
          accessToken: accessToken.trim(),
          refreshToken: refreshToken.trim(),
        );
      }

      if (accessToken != null || refreshToken != null) {
        await clearTokens();
      }

      return null;
    } catch (_) {
      throw const SessionStorageException('read_failed');
    }
  }

  Future<bool> hasCompleteSession() async {
    final tokens = await readTokens();
    return tokens != null;
  }

  Future<void> clearTokens() async {
    try {
      await _storage.delete(key: _accessTokenKey);
      await _storage.delete(key: _refreshTokenKey);
    } catch (_) {
      throw const SessionStorageException('clear_failed');
    }
  }

  Future<void> _clearTokensSilently() async {
    try {
      await _storage.delete(key: _accessTokenKey);
      await _storage.delete(key: _refreshTokenKey);
    } catch (_) {}
  }
}
