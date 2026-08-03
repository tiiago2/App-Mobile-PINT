import 'package:flutter/foundation.dart';
import '../database/daos/perfil_dao.dart';
import '../database/daos/assinaturas_dao.dart';
import '../database/daos/badges_dao.dart';
import 'auth_controller.dart';
import '../database/sync_helpers.dart';

class PerfilController extends ChangeNotifier {
  PerfilController._() {
    AuthController.instance.addListener(_handleAuthChanged);
  }

  static final PerfilController instance = PerfilController._();

  bool _isLoading = false;
  String? _errorMessage;

  Map<String, dynamic>? _perfilData;
  List<int> _signatureBadgeIds = const [];
  List<Map<String, dynamic>> _conqueredBadges = const [];
  Map<String, dynamic>? _learningPathProgress;

  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  Map<String, dynamic>? get perfilData => _perfilData;
  List<int> get signatureBadgeIds => _signatureBadgeIds;
  List<Map<String, dynamic>> get conqueredBadges => _conqueredBadges;
  Map<String, dynamic>? get learningPathProgress => _learningPathProgress;

  void _handleAuthChanged() {
    if (!AuthController.instance.isAuthenticated) {
      _perfilData = null;
      _signatureBadgeIds = const [];
      _conqueredBadges = const [];
      _learningPathProgress = null;
      _errorMessage = null;
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> carregarDadosPerfil() async {
    final user = AuthController.instance.currentUser;
    final userId = intOrNull(user?['id'] ?? user?['user_id'] ?? user?['id_utilizador']);

    if (userId == null || userId <= 0) {
      _errorMessage = 'Utilizador não autenticado.';
      notifyListeners();
      return;
    }

    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      // 1. Info Utilizador
      final perfil = await PerfilDao.instance.lerPerfilComArea(userId);
      _perfilData = perfil;

      if (perfil != null) {
        final idArea = intOrNull(perfil['id_area']);
        if (idArea != null && idArea > 0) {
          // 4. Learning Path
          _learningPathProgress = await PerfilDao.instance.obterProgressoLearningPath(userId, idArea);
        }
      }

      // 2. Assinatura Digital Badges
      _signatureBadgeIds = await AssinaturasDao.instance.obterIdsBadgesAssinatura(userId);

      // 3. Badges Conquistados
      _conqueredBadges = await BadgesDao.instance.obterBadgesConquistados(userId);

      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _isLoading = false;
      _errorMessage = 'Erro ao carregar dados locais: $e';
      notifyListeners();
    }
  }
}
