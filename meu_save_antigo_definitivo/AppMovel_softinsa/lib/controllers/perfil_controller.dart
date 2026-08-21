import 'dart:async';
import 'package:flutter/foundation.dart';

import '../database/daos/assinaturas_dao.dart';
import '../database/daos/badges_assinatura_dao.dart';
import '../database/daos/learning_paths_dao.dart';
import '../database/daos/perfil_dao.dart';
import '../database/daos/registo_badges.dart';
import '../database/sync_helpers.dart';
import '../services/api_service.dart';
import 'auth_controller.dart';

enum PerfilStatus {
  idle,
  loading,
  ready,
  error,
}

class PerfilController extends ChangeNotifier {
  PerfilController._();

  static final PerfilController instance = PerfilController._();

  final PerfilDao _perfilDao = PerfilDao.instance;
  final BadgesAssinaturaDao _assinaturaDao = BadgesAssinaturaDao.instance;
  final AssinaturasDao _assinaturasDao = AssinaturasDao.instance;
  final LearningPathsDao _learningPathsDao = LearningPathsDao.instance;
  final ApiService _apiService = ApiService();

  PerfilStatus _status = PerfilStatus.idle;
  Map<String, dynamic>? _perfil;
  List<Map<String, dynamic>> _badgesAssinatura = [];
  List<Map<String, dynamic>> _badgesConquistados = [];
  Map<String, dynamic>? _learningPathInfo;
  String? _errorMessage;

  PerfilStatus get status => _status;
  Map<String, dynamic>? get perfil => _perfil;
  List<Map<String, dynamic>> get badgesAssinatura => _badgesAssinatura;
  List<Map<String, dynamic>> get badgesConquistados => _badgesConquistados;
  Map<String, dynamic>? get learningPathInfo => _learningPathInfo;
  String? get errorMessage => _errorMessage;

  Future<void> carregar() async {
    final userId = AuthController.instance.currentUser?['id'] as int? ??
        AuthController.instance.currentUser?['id_utilizador'] as int?;

    if (userId == null) {
      _perfil = null;
      _badgesAssinatura = [];
      _badgesConquistados = [];
      _learningPathInfo = null;
      _status = PerfilStatus.ready;
      notifyListeners();
      return;
    }

    _status = PerfilStatus.loading;
    _errorMessage = null;
    notifyListeners();

    try {
      // 1. Carregar Perfil SQLite Local
      _perfil = await _perfilDao.getPerfil(userId);
      _perfil ??= AuthController.instance.currentUser;

      // 2. Carregar Badges de Assinatura
      final assinatura = await _assinaturasDao.getAssinaturaPorProprietario(userId);
      final idAssinaturaLocal = intOrNull(assinatura?['id_assinatura_local'] ?? assinatura?['id_assinatura']);
      if (idAssinaturaLocal != null) {
        _badgesAssinatura = await _assinaturaDao.getBadgesDaAssinatura(idAssinaturaLocal);
      } else {
        _badgesAssinatura = await _assinaturaDao.getBadgesDaAssinatura(userId);
      }

      // 3. Carregar Learning Path do utilizador
      final lpMap = _perfil?['learning_path'] ?? _perfil?['learningPath'];
      final lpId = intOrNull(_perfil?['id_learning_path'] ?? (lpMap is Map ? lpMap['id_learning_path'] ?? lpMap['id'] : null));
      if (lpId != null) {
        _learningPathInfo = await _learningPathsDao.getLearningPath(lpId);
      }

      // 4. Carregar Badges Conquistados do Utilizador (Registo de Badges)
      _badgesConquistados = await RegistoBadgesDao.instance.getRegistosDoUtilizador(userId);

      _status = PerfilStatus.ready;
      notifyListeners();
    } catch (e) {
      _status = PerfilStatus.error;
      _errorMessage = e.toString();
      notifyListeners();
    }
  }

  Future<void> atualizarPerfil({
    String? nome,
    String? email,
    String? telefone,
    String? fotoUrl,
  }) async {
    final userId = AuthController.instance.currentUser?['id'] as int? ??
        AuthController.instance.currentUser?['id_utilizador'] as int?;
    if (userId == null) throw Exception('utilizador_nao_autenticado');

    final updatedMap = <String, dynamic>{
      'id_utilizador': userId,
      'nome': nome ?? _perfil?['nome'] ?? '',
      'email': email ?? _perfil?['email'] ?? '',
      'telefone': telefone ?? _perfil?['telefone'],
      'foto': fotoUrl ?? _perfil?['foto'],
    };

    await _perfilDao.guardarPerfilLocal(userId: userId, perfil: updatedMap);

    // Tentar atualizar no servidor via API se online
    final accessToken = AuthController.instance.accessToken;
    if (accessToken != null && accessToken.isNotEmpty) {
      try {
        await _apiService.getUser(accessToken: accessToken);
      } catch (_) {}
    }

    await carregar();
  }

  Future<void> atualizarBadgesAssinatura(List<int> badgeIds) async {
    final userId = AuthController.instance.currentUser?['id'] as int? ??
        AuthController.instance.currentUser?['id_utilizador'] as int?;
    if (userId == null) throw Exception('utilizador_nao_autenticado');

    final idPerfil = _perfil?['id_perfil_local'] as int? ?? userId;
    for (final bId in badgeIds) {
      try {
        await _assinaturaDao.insertBadgeAssinatura(idPerfil, bId);
      } catch (_) {}
    }

    await carregar();
  }
}
