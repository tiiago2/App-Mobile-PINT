import 'dart:async';
import 'package:flutter/foundation.dart';

import '../database/daos/objetivo_dao.dart';
import 'auth_controller.dart';

enum ObjetivosStatus {
  idle,
  loading,
  ready,
  error,
}

class ObjetivosController extends ChangeNotifier {
  ObjetivosController._();

  static final ObjetivosController instance = ObjetivosController._();

  final ObjetivosDao _objetivosDao = ObjetivosDao.instance;
  StreamSubscription<int>? _changesSubscription;

  ObjetivosStatus _status = ObjetivosStatus.idle;
  List<Map<String, dynamic>> _objetivos = [];
  String? _errorMessage;

  ObjetivosStatus get status => _status;
  List<Map<String, dynamic>> get objetivos => _objetivos;
  String? get errorMessage => _errorMessage;

  List<Map<String, dynamic>> get objetivosAtivos {
    final now = DateTime.now();
    return _objetivos.where((obj) {
      final dataFinalStr = obj['data_final'] as String? ?? obj['deadline'] as String?;
      if (dataFinalStr == null) return true;
      final dt = DateTime.tryParse(dataFinalStr);
      if (dt == null) return true;
      final isConcluido = obj['concluido'] == 1 || obj['data_conclusao'] != null;
      return !isConcluido && dt.isAfter(now.subtract(const Duration(days: 1)));
    }).toList();
  }

  List<Map<String, dynamic>> get objetivosExpirados {
    final now = DateTime.now();
    return _objetivos.where((obj) {
      final dataFinalStr = obj['data_final'] as String? ?? obj['deadline'] as String?;
      if (dataFinalStr == null) return false;
      final dt = DateTime.tryParse(dataFinalStr);
      if (dt == null) return false;
      final isConcluido = obj['concluido'] == 1 || obj['data_conclusao'] != null;
      return isConcluido || dt.isBefore(now.subtract(const Duration(days: 1)));
    }).toList();
  }

  void initialize() {
    _changesSubscription ??= _objetivosDao.changes.listen((userId) {
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

  Future<void> carregar() async {
    final userId = AuthController.instance.currentUser?['id'] as int? ??
        AuthController.instance.currentUser?['id_utilizador'] as int?;

    if (userId == null) {
      _objetivos = [];
      _status = ObjetivosStatus.ready;
      notifyListeners();
      return;
    }

    _status = ObjetivosStatus.loading;
    _errorMessage = null;
    notifyListeners();

    try {
      _objetivos = await _objetivosDao.getObjetivosDoUtilizador(userId);
      _status = ObjetivosStatus.ready;
      notifyListeners();
    } catch (e) {
      _status = ObjetivosStatus.error;
      _errorMessage = e.toString();
      notifyListeners();
    }
  }

  Future<int> criarObjetivo({
    required int badgeId,
    required String dataFinal,
    String? titulo,
    String? descricao,
  }) async {
    final userId = AuthController.instance.currentUser?['id'] as int? ??
        AuthController.instance.currentUser?['id_utilizador'] as int?;
    if (userId == null) throw Exception('utilizador_nao_autenticado');

    final localId = await _objetivosDao.criarObjetivoLocal(
      userId: userId,
      badgeId: badgeId,
      dataFinal: dataFinal,
      titulo: titulo,
      descricao: descricao,
    );

    await carregar();
    return localId;
  }

  Future<void> apagarObjetivo(int localId) async {
    final userId = AuthController.instance.currentUser?['id'] as int? ??
        AuthController.instance.currentUser?['id_utilizador'] as int?;
    if (userId == null) throw Exception('utilizador_nao_autenticado');

    await _objetivosDao.eliminarObjetivoLocal(
      userId: userId,
      localId: localId,
    );

    await carregar();
  }
}
