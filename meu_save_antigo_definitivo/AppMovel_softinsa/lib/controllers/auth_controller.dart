import 'package:flutter/foundation.dart';

import '../database/database_helper.dart';
import '../database/database_schema.dart';
import '../database/daos/perfil_dao.dart';
import '../database/sync_helpers.dart';
import '../database/local/secure_storage.dart';
import '../services/api_service.dart';
import '../services/session_storage.dart';

enum AuthStatus {
  checking,
  unauthenticated,
  firstAccessRequired,
  authenticatedOnline,
  authenticatedOffline,
}

class AuthController extends ChangeNotifier {
  AuthController._();

  static final AuthController instance = AuthController._();

  final SessionStorage _sessionStorage = SessionStorage.instance;
  final ApiService _apiService = ApiService();

  AuthStatus _status = AuthStatus.checking;
  String? _accessToken;
  String? _refreshToken;
  String? _firstAccessEmail;
  Map<String, dynamic>? _currentUser;
  Future<void>? _initializationFuture;

  AuthStatus get status => _status;

  bool get isAuthenticated =>
      _status == AuthStatus.authenticatedOnline ||
      _status == AuthStatus.authenticatedOffline;

  bool get isOffline => _status == AuthStatus.authenticatedOffline;

  String? get accessToken => _accessToken;

  String? get firstAccessEmail => _firstAccessEmail;

  Map<String, dynamic>? get currentUser => _currentUser;

  Future<void> initialize() {
    _initializationFuture ??= _initialize();
    return _initializationFuture!;
  }

  Future<void> completeLogin({
    required String token,
    required String refreshToken,
    Map<String, dynamic>? userJson,
  }) async {
    final cleanAccessToken = token.trim();
    final cleanRefreshToken = refreshToken.trim();

    if (cleanAccessToken.isEmpty || cleanRefreshToken.isEmpty) {
      throw const SessionStorageException('invalid_tokens');
    }

    try {
      await _sessionStorage.saveTokens(
        accessToken: cleanAccessToken,
        refreshToken: cleanRefreshToken,
      );

      await SecureStorage.saveToken(cleanAccessToken);

      _accessToken = cleanAccessToken;
      _refreshToken = cleanRefreshToken;

      if (userJson != null && userJson.isNotEmpty) {
        _currentUser = userJson;
      } else {
        _currentUser = await _apiService.getUser(accessToken: cleanAccessToken);
      }

      await _guardarPerfilLocalSePossivel(_currentUser);
      _firstAccessEmail = null;
      _setStatus(AuthStatus.authenticatedOnline);
    } catch (e) {
      await logout();
      rethrow;
    }
  }

  void requireFirstAccess(String email) {
    _firstAccessEmail = email.trim();
    _clearMemorySession(clearFirstAccessEmail: false);
    _setStatus(AuthStatus.firstAccessRequired);
  }

  void clearFirstAccessRequirement() {
    _firstAccessEmail = null;

    if (_status == AuthStatus.firstAccessRequired) {
      _setStatus(AuthStatus.unauthenticated);
      return;
    }

    notifyListeners();
  }

  Future<void> logout() async {
    await _sessionStorage.clearTokens();
    await SecureStorage.deleteToken();
    await _limparPerfilLocalSePossivel();
    await _limparBadgesLocalSePossivel();
    _clearMemorySession();
    _setStatus(AuthStatus.unauthenticated);
  }

  Future<String?> renovarAccessTokenParaPedido() async {
    final refreshToken = _refreshToken;

    if (refreshToken == null || refreshToken.trim().isEmpty) {
      return null;
    }

    try {
      final newAccessToken = await _apiService.refreshAccessToken(
        refreshToken: refreshToken,
      );

      await _sessionStorage.saveTokens(
        accessToken: newAccessToken,
        refreshToken: refreshToken,
      );

      await SecureStorage.saveToken(newAccessToken);

      _accessToken = newAccessToken;

      if (_status == AuthStatus.authenticatedOffline) {
        _setStatus(AuthStatus.authenticatedOnline);
      }

      return newAccessToken;
    } on ApiException catch (error) {
      if (error.statusCode == 401) {
        await _clearInvalidStoredSession();
        _setStatus(AuthStatus.unauthenticated);
        return null;
      }

      if (error.message == 'connection' || error.message == 'timeout') {
        if (isAuthenticated) {
          _setStatus(AuthStatus.authenticatedOffline);
        }
        return null;
      }

      return null;
    } on SessionStorageException {
      return null;
    }
  }

  Future<void> _initialize() async {
    _setStatus(AuthStatus.checking);

    try {
      final tokens = await _sessionStorage.readTokens();

      if (tokens == null) {
        _clearMemorySession();
        _setStatus(AuthStatus.unauthenticated);
        return;
      }

      _accessToken = tokens.accessToken;
      _refreshToken = tokens.refreshToken;
      await _validateStoredSession(tokens);
    } on SessionStorageException {
      _clearMemorySession();
      _setStatus(AuthStatus.unauthenticated);
    } catch (_) {
      _clearMemorySession();
      _setStatus(AuthStatus.unauthenticated);
    }
  }

  Future<void> _validateStoredSession(SessionTokens tokens) async {
    try {
      _currentUser = await _apiService.getUser(
        accessToken: tokens.accessToken,
      );
      await _guardarPerfilLocalSePossivel(_currentUser);
      _setStatus(AuthStatus.authenticatedOnline);
    } on ApiException catch (error) {
      if (error.statusCode == 401) {
        await _tryRefreshSession(tokens);
        return;
      }

      await _carregarPerfilLocalSePossivel();
      _setStatus(AuthStatus.authenticatedOffline);
    }
  }

  Future<void> _tryRefreshSession(SessionTokens tokens) async {
    try {
      final newAccessToken = await _apiService.refreshAccessToken(
        refreshToken: tokens.refreshToken,
      );

      await _sessionStorage.saveTokens(
        accessToken: newAccessToken,
        refreshToken: tokens.refreshToken,
      );

      await SecureStorage.saveToken(newAccessToken);

      _accessToken = newAccessToken;
      _refreshToken = tokens.refreshToken;
      _currentUser = await _apiService.getUser(accessToken: newAccessToken);
      await _guardarPerfilLocalSePossivel(_currentUser);
      _setStatus(AuthStatus.authenticatedOnline);
    } on ApiException catch (error) {
      if (error.statusCode == 401) {
        await _clearInvalidStoredSession();
        _setStatus(AuthStatus.unauthenticated);
        return;
      }

      await _carregarPerfilLocalSePossivel();
      _setStatus(AuthStatus.authenticatedOffline);
    } on SessionStorageException {
      _clearMemorySession();
      _setStatus(AuthStatus.unauthenticated);
    }
  }

  Future<void> _clearInvalidStoredSession() async {
    try {
      await _sessionStorage.clearTokens();
    } on SessionStorageException {}

    await _limparPerfilLocalSePossivel();
    await _limparBadgesLocalSePossivel();
    _clearMemorySession();
  }

  Future<void> _guardarPerfilLocalSePossivel(
    Map<String, dynamic>? perfil,
  ) async {
    if (perfil == null || perfil.isEmpty) {
      return;
    }

    try {
      final userId = intOrNull(perfil['id'] ?? perfil['user_id'] ?? perfil['id_utilizador']);
      if (userId != null && userId > 0) {
        await PerfilDao.instance.aplicarPerfilRemoto(userId: userId, perfil: perfil);
      }
    } catch (_) {}
  }

  Future<void> _carregarPerfilLocalSePossivel() async {
    try {
      final db = await DatabaseHelper.instance.database;
      final rows = await db.query(DatabaseSchema.perfilTable, limit: 1);
      if (rows.isNotEmpty) {
        final row = rows.first;
        final userId = intOrNull(row['id_utilizador']);
        if (userId != null) {
          _currentUser = await PerfilDao.instance.lerPerfilDoUtilizador(userId);
        }
      }
    } catch (_) {}
  }

  Future<void> _limparPerfilLocalSePossivel() async {
    try {
      final db = await DatabaseHelper.instance.database;
      await db.delete(DatabaseSchema.perfilTable);
    } catch (_) {}
  }

  Future<void> _limparBadgesLocalSePossivel() async {
    try {
      final db = await DatabaseHelper.instance.database;
      await db.delete(DatabaseSchema.badgesTable);
      await db.delete(DatabaseSchema.registoBadgesTable);
    } catch (_) {}
  }

  void _clearMemorySession({bool clearFirstAccessEmail = true}) {
    _accessToken = null;
    _refreshToken = null;
    _currentUser = null;

    if (clearFirstAccessEmail) {
      _firstAccessEmail = null;
    }
  }

  void _setStatus(AuthStatus status) {
    if (_status == status) {
      return;
    }

    _status = status;
    notifyListeners();
  }
}
