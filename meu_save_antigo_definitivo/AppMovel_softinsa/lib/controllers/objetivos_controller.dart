import 'package:flutter/foundation.dart';
import '../database/daos/objetivo_dao.dart';
import 'auth_controller.dart';
import '../database/sync_helpers.dart';
import '../database/sync_manager.dart';

class ObjetivosController extends ChangeNotifier {
  ObjetivosController._() {
    AuthController.instance.addListener(_handleAuthChanged);
  }

  static final ObjetivosController instance = ObjetivosController._();

  bool _isLoading = false;
  String? _errorMessage;

  List<Map<String, dynamic>> _ativos = const [];
  List<Map<String, dynamic>> _expirados = const [];
  List<Map<String, dynamic>> _disponiveisBadges = const [];

  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  List<Map<String, dynamic>> get ativos => _ativos;
  List<Map<String, dynamic>> get expirados => _expirados;
  List<Map<String, dynamic>> get disponiveisBadges => _disponiveisBadges;

  void _handleAuthChanged() {
    if (!AuthController.instance.isAuthenticated) {
      _ativos = const [];
      _expirados = const [];
      _disponiveisBadges = const [];
      _errorMessage = null;
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> carregarDadosObjetivos() async {
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
      // 1. Obter objetivos
      final todos = await ObjetivosDao.instance.obterObjetivosComBadges(userId);
      final now = DateTime.now();

      final listAtivos = <Map<String, dynamic>>[];
      final listExpirados = <Map<String, dynamic>>[];

      for (final obj in todos) {
        final dataFinalStr = obj['data_final']?.toString();
        final dataFinal = dataFinalStr != null ? DateTime.tryParse(dataFinalStr) : null;
        
        final daysLeft = dataFinal != null ? dataFinal.difference(now).inDays + 1 : 0;
        final diasRestantes = daysLeft < 0 ? 0 : daysLeft;

        final mapped = {
          'id': obj['id_objetivo_local'],
          'titulo': obj['nome_badge'] ?? '',
          'categoria': obj['categoria_badge'] ?? '',
          'deadline': dataFinalStr != null ? _formatDateDisplay(dataFinalStr) : '',
          'diasRestantes': diasRestantes,
          'progresso': obj['data_conclusao'] != null ? 1.0 : 0.0,
          'ativo': obj['data_conclusao'] == null && diasRestantes > 0,
          'imagem': obj['imagem'],
        };

        if (mapped['ativo'] == true) {
          listAtivos.add(mapped);
        } else {
          listExpirados.add(mapped);
        }
      }

      _ativos = listAtivos;
      _expirados = listExpirados;

      // 2. Obter badges disponíveis
      _disponiveisBadges = await ObjetivosDao.instance.obterBadgesDisponiveis(userId);

      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _isLoading = false;
      _errorMessage = 'Erro ao carregar dados dos objetivos: $e';
      notifyListeners();
    }
  }

  Future<void> criarNovoObjetivo({required int badgeId, required DateTime dataLimite}) async {
    final user = AuthController.instance.currentUser;
    final userId = intOrNull(user?['id'] ?? user?['user_id'] ?? user?['id_utilizador']);

    if (userId == null || userId <= 0) {
      throw Exception('Utilizador não autenticado.');
    }

    try {
      final dateStr = dataLimite.toIso8601String();
      await ObjetivosDao.instance.criarObjetivoLocal(
        userId: userId,
        badgeId: badgeId,
        dataFinal: dateStr,
      );

      // Recarregar dados locais
      await carregarDadosObjetivos();

      // Trigger sync em background
      SyncManager.instance.executePushSync(userId);
    } catch (e) {
      _errorMessage = 'Erro ao criar objetivo: $e';
      notifyListeners();
      rethrow;
    }
  }

  Future<void> eliminarObjetivo(int localId) async {
    final user = AuthController.instance.currentUser;
    final userId = intOrNull(user?['id'] ?? user?['user_id'] ?? user?['id_utilizador']);

    if (userId == null || userId <= 0) {
      throw Exception('Utilizador não autenticado.');
    }

    try {
      await ObjetivosDao.instance.eliminarObjetivoLocal(
        userId: userId,
        localId: localId,
      );

      // Recarregar dados locais
      await carregarDadosObjetivos();

      // Trigger sync em background
      SyncManager.instance.executePushSync(userId);
    } catch (e) {
      _errorMessage = 'Erro ao eliminar objetivo: $e';
      notifyListeners();
      rethrow;
    }
  }

  String _formatDateDisplay(String dateIso) {
    final parsed = DateTime.tryParse(dateIso);
    if (parsed == null) return dateIso;
    return '${parsed.day.toString().padLeft(2, '0')}/${parsed.month.toString().padLeft(2, '0')}/${parsed.year}';
  }
}
