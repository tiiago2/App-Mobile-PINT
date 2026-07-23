import 'package:flutter/foundation.dart';

import '../database/basededados.dart';
import '../services/api_service.dart';
import 'auth_controller.dart';

enum BadgesStatus {
  idle,
  loading,
  readyOnline,
  readyOffline,
  error,
}

class BadgesController extends ChangeNotifier {
  BadgesController._() {
    _authController.addListener(_handleAuthChanged);
  }

  static final BadgesController instance = BadgesController._();

  final ApiService _apiService = ApiService();
  final Basededados _basededados = Basededados.instance;
  final AuthController _authController = AuthController.instance;

  List<Map<String, dynamic>> _badges = const [];
  BadgesStatus _status = BadgesStatus.idle;
  String? _mensagemTecnica;
  Future<void>? _loadingFuture;

  List<Map<String, dynamic>> get badges => List.unmodifiable(_badges);

  BadgesStatus get status => _status;

  bool get isLoading => _status == BadgesStatus.loading;

  bool get hasData => _badges.isNotEmpty;

  String? get mensagemTecnica => _mensagemTecnica;

  Future<void> carregar({bool force = false}) {
    final loadingFuture = _loadingFuture;

    if (loadingFuture != null) {
      return loadingFuture;
    }

    _loadingFuture = _carregar(force: force).whenComplete(() {
      _loadingFuture = null;
    });

    return _loadingFuture!;
  }

  Future<void> _carregar({required bool force}) async {
    final cache = await _lerCacheSePossivel();
    final temCache = cache.isNotEmpty;

    if (temCache) {
      _publicarBadges(cache, BadgesStatus.readyOffline);
    } else {
      _setStatus(BadgesStatus.loading);
    }

    if (!_authController.isAuthenticated) {
      _badges = const [];
      _mensagemTecnica = null;
      _setStatus(BadgesStatus.idle);
      return;
    }

    final accessToken = _authController.accessToken;
    if (accessToken == null || accessToken.trim().isEmpty) {
      if (!temCache) {
        _setStatus(BadgesStatus.error, mensagemTecnica: 'missing_access_token');
      }
      return;
    }

    try {
      final response = await _getMeBadgesComRefresh(accessToken);
      final badges = response.badges;

      try {
        await _basededados.substituirBadges(badges);
      } on BaseDadosException {}

      _publicarBadges(badges, BadgesStatus.readyOnline);
    } on ApiException catch (error) {
      if (error.message == 'connection' || error.message == 'timeout') {
        if (temCache || _badges.isNotEmpty) {
          _setStatus(BadgesStatus.readyOffline);
        } else {
          _setStatus(BadgesStatus.error, mensagemTecnica: error.message);
        }
        return;
      }

      if (temCache || _badges.isNotEmpty) {
        _setStatus(BadgesStatus.readyOffline);
      } else {
        _setStatus(BadgesStatus.error, mensagemTecnica: error.message);
      }
    }
  }

  Future<MeBadgesApiResponse> _getMeBadgesComRefresh(
    String accessToken,
  ) async {
    try {
      return await _apiService.getMeBadges(accessToken: accessToken);
    } on ApiException catch (error) {
      if (error.statusCode != 401) {
        rethrow;
      }

      final newAccessToken =
          await _authController.renovarAccessTokenParaPedido();

      if (newAccessToken == null || newAccessToken.trim().isEmpty) {
        rethrow;
      }

      return _apiService.getMeBadges(accessToken: newAccessToken);
    }
  }

  Future<List<Map<String, dynamic>>> _lerCacheSePossivel() async {
    try {
      return await _basededados.lerBadges();
    } on BaseDadosException {
      return const [];
    }
  }

  void _publicarBadges(
    List<Map<String, dynamic>> badges,
    BadgesStatus status,
  ) {
    _badges = badges.map(_normalizarBadge).toList(growable: false);
    _mensagemTecnica = null;

    if (_status == status) {
      notifyListeners();
    } else {
      _setStatus(status);
    }
  }

  Map<String, dynamic> _normalizarBadge(Map<String, dynamic> badgeOriginal) {
    final area = _toMapOrNull(badgeOriginal['area']);
    final nivel = _toMapOrNull(badgeOriginal['nivel']);

    return {
      ...badgeOriginal,
      'id': badgeOriginal['id_badge'],
      'titulo': badgeOriginal['nome_badge'],
      'descricao': badgeOriginal['descricao_badge'],
      'pontos': badgeOriginal['pontos_badge'],
      'validadeDias': badgeOriginal['validade'],
      'areaNome': area?['nome_area'],
      'nivelNome': nivel?['nome_nivel'],
      'minhaArea': badgeOriginal['minha_area'],
      'dataAquisicao': badgeOriginal['data_obtencao'],
    };
  }

  Map<String, dynamic>? _toMapOrNull(Object? value) {
    return value is Map<String, dynamic> ? value : null;
  }

  void _handleAuthChanged() {
    if (_authController.status == AuthStatus.unauthenticated) {
      _badges = const [];
      _mensagemTecnica = null;
      _setStatus(BadgesStatus.idle);
    }
  }

  void _setStatus(BadgesStatus status, {String? mensagemTecnica}) {
    final changed = _status != status || _mensagemTecnica != mensagemTecnica;

    _status = status;
    _mensagemTecnica = mensagemTecnica;

    if (changed) {
      notifyListeners();
    }
  }
}
