import 'dart:async';
import 'package:flutter/foundation.dart';

import '../database/daos/submissao_dao.dart';
import '../services/api_service.dart';
import 'auth_controller.dart';

enum CandidaturasStatus {
  idle,
  loading,
  ready,
  error,
}

class CandidaturasController extends ChangeNotifier {
  CandidaturasController._();

  static final CandidaturasController instance = CandidaturasController._();

  final SubmissoesDao _submissoesDao = SubmissoesDao.instance;
  final ApiService _apiService = ApiService();
  StreamSubscription<int>? _changesSubscription;

  CandidaturasStatus _status = CandidaturasStatus.idle;
  List<Map<String, dynamic>> _candidaturas = [];
  String? _errorMessage;

  CandidaturasStatus get status => _status;
  List<Map<String, dynamic>> get candidaturas => _candidaturas;
  String? get errorMessage => _errorMessage;

  void initialize() {
    _changesSubscription ??= _submissoesDao.changes.listen((userId) {
      final currentUserId = AuthController.instance.currentUser?['id'] as int? ??
          AuthController.instance.currentUser?['id_utilizador'] as int?;
      if (userId == -1 || (currentUserId != null && userId == currentUserId)) {
        carregar();
      }
    });
    carregar();
  }

  @override
  void dispose() {
    _changesSubscription?.cancel();
    super.dispose();
  }

  Future<void> carregar({bool force = false}) async {
    final userId = AuthController.instance.currentUser?['id'] as int? ??
        AuthController.instance.currentUser?['id_utilizador'] as int?;

    if (userId == null) {
      _candidaturas = [];
      _status = CandidaturasStatus.ready;
      notifyListeners();
      return;
    }

    _status = CandidaturasStatus.loading;
    _errorMessage = null;
    notifyListeners();

    try {
      // 1. Ler candidaturas da BD local SQLite
      _candidaturas = await _submissoesDao.lerSubmissoesDoUtilizador(userId);
      _status = CandidaturasStatus.ready;
      notifyListeners();

      // 2. Se houver access token online, sincronizar com a API remota
      final accessToken = AuthController.instance.accessToken;
      if (accessToken != null && accessToken.isNotEmpty) {
        try {
          final response = await _apiService.getMeBadges(accessToken: accessToken);
          // Atualizar candidaturas a partir dos badges obtidos/submetidos
          if (response.badges.isNotEmpty) {
            _candidaturas = await _submissoesDao.lerSubmissoesDoUtilizador(userId);
            notifyListeners();
          }
        } catch (_) {
          // Mantém os dados da base de dados local offline se a API não responder
        }
      }
    } catch (e) {
      _status = CandidaturasStatus.error;
      _errorMessage = e.toString();
      notifyListeners();
    }
  }

  Future<int> criarRascunho({required int badgeId}) async {
    final userId = AuthController.instance.currentUser?['id'] as int? ??
        AuthController.instance.currentUser?['id_utilizador'] as int?;
    if (userId == null) throw Exception('utilizador_nao_autenticado');

    final localId = await _submissoesDao.criarRascunhoLocal(
      userId: userId,
      badgeId: badgeId,
    );
    await carregar();
    return localId;
  }

  Future<void> submeterCandidatura({
    required int localId,
    String? comentario,
  }) async {
    final userId = AuthController.instance.currentUser?['id'] as int? ??
        AuthController.instance.currentUser?['id_utilizador'] as int?;
    if (userId == null) throw Exception('utilizador_nao_autenticado');

    await _submissoesDao.pedirSubmissaoLocal(
      userId: userId,
      localId: localId,
      comentario: comentario,
    );
    await carregar();
  }

  Future<void> eliminarCandidatura(int localId) async {
    final userId = AuthController.instance.currentUser?['id'] as int? ??
        AuthController.instance.currentUser?['id_utilizador'] as int?;
    if (userId == null) throw Exception('utilizador_nao_autenticado');

    await _submissoesDao.eliminarSubmissaoLocal(
      userId: userId,
      localId: localId,
    );
    await carregar();
  }
}
