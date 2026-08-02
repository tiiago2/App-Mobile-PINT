import 'dart:async';
import 'package:flutter/foundation.dart';

import '../database/daos/notificacao.dart';
import 'auth_controller.dart';

enum NotificacoesStatus {
  idle,
  loading,
  ready,
  error,
}

class NotificacoesController extends ChangeNotifier {
  NotificacoesController._();

  static final NotificacoesController instance = NotificacoesController._();

  final NotificacoesDao _notificacoesDao = NotificacoesDao.instance;

  NotificacoesStatus _status = NotificacoesStatus.idle;
  List<Map<String, dynamic>> _notificacoes = [];
  int _naoLidasCount = 0;
  String? _errorMessage;

  NotificacoesStatus get status => _status;
  List<Map<String, dynamic>> get notificacoes => _notificacoes;
  int get naoLidasCount => _naoLidasCount;
  String? get errorMessage => _errorMessage;

  Future<void> carregar() async {
    final userId = AuthController.instance.currentUser?['id'] as int? ??
        AuthController.instance.currentUser?['id_utilizador'] as int?;

    if (userId == null) {
      _notificacoes = [];
      _naoLidasCount = 0;
      _status = NotificacoesStatus.ready;
      notifyListeners();
      return;
    }

    _status = NotificacoesStatus.loading;
    _errorMessage = null;
    notifyListeners();

    try {
      final todas = await _notificacoesDao.getNotificacoes();
      _notificacoes = todas.where((n) {
        final uId = n['id_utilizador'] as int?;
        return uId == null || uId == userId;
      }).toList();

      _naoLidasCount = _notificacoes.where((n) => n['lida'] == 0).length;
      _status = NotificacoesStatus.ready;
      notifyListeners();
    } catch (e) {
      _status = NotificacoesStatus.error;
      _errorMessage = e.toString();
      notifyListeners();
    }
  }

  Future<void> marcarComoLida(int idNotificacao) async {
    await _notificacoesDao.marcarComoLida(idNotificacao);
    await carregar();
  }

  Future<void> marcarTodasComoLidas() async {
    for (final n in _notificacoes) {
      final id = n['id_notificacao'] as int?;
      if (id != null && n['lida'] == 0) {
        await _notificacoesDao.marcarComoLida(id);
      }
    }
    await carregar();
  }
}
