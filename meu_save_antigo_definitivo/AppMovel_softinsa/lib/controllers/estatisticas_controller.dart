import 'dart:async';
import 'package:flutter/foundation.dart';

import '../database/daos/badges_dao.dart';
import '../database/daos/outros_users_dao.dart';
import '../database/daos/registo_badges.dart';
import 'auth_controller.dart';

enum EstatisticasStatus {
  idle,
  loading,
  ready,
  error,
}

class EstatisticasController extends ChangeNotifier {
  EstatisticasController._();

  static final EstatisticasController instance = EstatisticasController._();

  final RegistoBadgesDao _registoBadgesDao = RegistoBadgesDao.instance;
  final BadgesDao _badgesDao = BadgesDao.instance;
  final OutrosUsersDao _outrosUsersDao = OutrosUsersDao.instance;

  EstatisticasStatus _status = EstatisticasStatus.idle;
  int _totalBadgesConquistados = 0;
  int _posicaoGeral = 1;
  int _totalPontos = 0;
  final List<Map<String, dynamic>> _distribuicaoPorArea = [];
  final List<Map<String, dynamic>> _badgesPorNivel = [];
  List<Map<String, dynamic>> _rankingGeral = [];
  String? _errorMessage;

  EstatisticasStatus get status => _status;
  int get totalBadgesConquistados => _totalBadgesConquistados;
  int get posicaoGeral => _posicaoGeral;
  int get totalPontos => _totalPontos;
  List<Map<String, dynamic>> get distribuicaoPorArea => _distribuicaoPorArea;
  List<Map<String, dynamic>> get badgesPorNivel => _badgesPorNivel;
  List<Map<String, dynamic>> get rankingGeral => _rankingGeral;
  String? get errorMessage => _errorMessage;

  Future<void> carregar() async {
    final userId = AuthController.instance.currentUser?['id'] as int? ??
        AuthController.instance.currentUser?['id_utilizador'] as int?;

    if (userId == null) {
      _status = EstatisticasStatus.ready;
      notifyListeners();
      return;
    }

    _status = EstatisticasStatus.loading;
    _errorMessage = null;
    notifyListeners();

    try {
      // 1. Obter registos de badges do utilizador da BD local
      final registos = await _registoBadgesDao.getRegistosDoUtilizador(userId);
      _totalBadgesConquistados = registos.length;

      // 2. Calcular pontos totais
      int pontos = 0;
      for (final r in registos) {
        final badgeId = r['id_badge'] as int?;
        if (badgeId != null) {
          final badge = await _badgesDao.getBadge(badgeId);
          if (badge != null) {
            pontos += (badge['pontos_badge'] as int? ?? 0);
          }
        }
      }
      _totalPontos = pontos;

      // 3. Obter utilizadores para o ranking
      _rankingGeral = await _outrosUsersDao.getUsers();
      
      // Encontrar a posição do utilizador no ranking
      int pos = 1;
      for (int i = 0; i < _rankingGeral.length; i++) {
        final uId = _rankingGeral[i]['id_utilizador'] as int?;
        if (uId == userId) {
          pos = i + 1;
          break;
        }
      }
      _posicaoGeral = pos;

      _status = EstatisticasStatus.ready;
      notifyListeners();
    } catch (e) {
      _status = EstatisticasStatus.error;
      _errorMessage = e.toString();
      notifyListeners();
    }
  }
}
