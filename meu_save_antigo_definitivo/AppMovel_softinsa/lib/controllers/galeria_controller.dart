import 'package:flutter/foundation.dart';
import '../database/daos/badges_dao.dart';
import '../database/daos/perfil_dao.dart';
import '../database/sync_helpers.dart';
import '../database/sync_manager.dart';
import 'auth_controller.dart';

class GaleriaController extends ChangeNotifier {
  GaleriaController._();
  static final GaleriaController instance = GaleriaController._();

  List<Map<String, dynamic>> _todosBadges = [];
  List<Map<String, dynamic>> _sugeridosBadges = [];
  bool _isLoading = false;
  String? _errorMessage;

  List<Map<String, dynamic>> get todosBadges => _todosBadges;
  List<Map<String, dynamic>> get sugeridosBadges => _sugeridosBadges;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  Future<void> carregarDados() async {
    final user = AuthController.instance.currentUser;
    final userId = intOrNull(user?['id'] ?? user?['user_id'] ?? user?['id_utilizador']);

    if (userId == null) {
      _errorMessage = 'Utilizador não autenticado.';
      _isLoading = false;
      notifyListeners();
      return;
    }

    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      // 1. Executa o Pull Sync para trazer atualizações do servidor antes de ler localmente
      try {
        await SyncManager.instance.executePullSync(userId);
      } catch (syncError) {
        print('⚠️ [GaleriaController] Erro na sincronização antes da leitura: $syncError');
      }

      // 2. Obter id_area do perfil
      final perfil = await PerfilDao.instance.lerPerfilComArea(userId);
      final userAreaId = intOrNull(perfil?['id_area']) ?? 0;

      // 3. Carregar todos os badges com estados calculados do SQLite
      _todosBadges = await BadgesDao.instance.obterTodosBadgesParaGaleria(
        userId: userId,
        userAreaId: userAreaId,
      );

      // 4. Carregar badges sugeridos pelo motor local do SQLite
      _sugeridosBadges = await BadgesDao.instance.obterBadgesSugeridos(
        userId: userId,
        userAreaId: userAreaId,
      );

      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _isLoading = false;
      _errorMessage = 'Erro ao carregar dados da galeria: $e';
      notifyListeners();
    }
  }
}
