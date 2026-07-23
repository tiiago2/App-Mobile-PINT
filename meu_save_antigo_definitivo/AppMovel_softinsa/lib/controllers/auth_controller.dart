import 'package:flutter/foundation.dart';

import '../database/basededados.dart';
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
  final Basededados _basededados = Basededados.instance;

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
    required String accessToken,
    required String refreshToken,
    Map<String, dynamic>? user,
  }) async {
    final cleanAccessToken = accessToken.trim();
    final cleanRefreshToken = refreshToken.trim();

    if (cleanAccessToken.isEmpty || cleanRefreshToken.isEmpty) {
      throw const SessionStorageException('invalid_tokens');
    }

    await _sessionStorage.saveTokens(
      accessToken: cleanAccessToken,
      refreshToken: cleanRefreshToken,
    );

    _accessToken = cleanAccessToken;
    _refreshToken = cleanRefreshToken;

    try {
      _currentUser = await _apiService.getUser(accessToken: cleanAccessToken);
      await _guardarPerfilLocalSePossivel(_currentUser);
    } on ApiException catch (error) {
      if (error.statusCode == 401) {
        await _clearInvalidStoredSession();
        _setStatus(AuthStatus.unauthenticated);
        rethrow;
      }

      _currentUser = user;
      await _guardarPerfilLocalSePossivel(user);
    }

    _firstAccessEmail = null;
    _setStatus(AuthStatus.authenticatedOnline);
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
      await _basededados.guardarPerfil(perfil);
    } on BaseDadosException {}
  }

  Future<void> _carregarPerfilLocalSePossivel() async {
    try {
      _currentUser = await _basededados.lerPerfil() ?? _currentUser;
    } on BaseDadosException {}
  }

  Future<void> _limparPerfilLocalSePossivel() async {
    try {
      await _basededados.limparPerfil();
    } on BaseDadosException {}
  }

  Future<void> _limparBadgesLocalSePossivel() async {
    try {
      await _basededados.limparBadges();
    } on BaseDadosException {}
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
