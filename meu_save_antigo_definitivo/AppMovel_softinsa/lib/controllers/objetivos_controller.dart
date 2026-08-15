import 'package:flutter/foundation.dart';
import 'package:sqflite/sqflite.dart';
import '../database/daos/objetivo_dao.dart';
import '../database/database_helper.dart';
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
      final db = await DatabaseHelper.instance.database;
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

        final badgeId = obj['id_badge'];
        double progress = 0.0;
        final dataConclusaoStr = obj['data_conclusao']?.toString() ?? '';
        final concluido = dataConclusaoStr.isNotEmpty;

        if (concluido) {
          progress = 1.0;
        } else if (badgeId != null) {
          // Buscar se há submissão para este badge
          final subRes = await db.rawQuery('''
            SELECT id_submissao, id_submissao_local, status
            FROM submissoes
            WHERE id_utilizador = ? AND id_badge = ?
              AND (deleted_submissao = 0 OR deleted_submissao IS NULL OR deleted_submissao = 'false' OR deleted_submissao = '0')
            LIMIT 1
          ''', [userId, badgeId]);

          if (subRes.isNotEmpty) {
            final sub = subRes.first;
            final String statusStr = sub['status']?.toString().toLowerCase() ?? '';
            
            if (statusStr == 'aceite' || statusStr == 'aceite talent' || statusStr == 'aprovado' || statusStr == 'aprovada') {
              progress = 1.0;
            } else {
              final subId = sub['id_submissao'];
              final subLocalId = sub['id_submissao_local'];

              final reqsCountRes = await db.rawQuery('''
                SELECT COUNT(*) as cnt FROM badges_requisitos WHERE id_badge = ?
              ''', [badgeId]);
              final totalReqs = Sqflite.firstIntValue(reqsCountRes) ?? 0;

              final compReqsRes = await db.rawQuery('''
                SELECT COUNT(DISTINCT id_requisito) as cnt
                FROM documentos_submissao
                WHERE (
                  (id_submissao IS NOT NULL AND id_submissao = ?) 
                  OR 
                  (id_submissao_local IS NOT NULL AND id_submissao_local = ?)
                )
                AND (deleted_file = 0 OR deleted_file IS NULL OR deleted_file = '')
              ''', [subId, subLocalId]);
              final compReqs = Sqflite.firstIntValue(compReqsRes) ?? 0;

              if (totalReqs > 0) {
                progress = compReqs / totalReqs;
              }
            }
          }
        }

        final mapped = {
          'id': obj['id_objetivo_local'],
          'titulo': obj['nome_badge'] ?? '',
          'categoria': obj['categoria_badge'] ?? '',
          'deadline': dataFinalStr != null ? _formatDateDisplay(dataFinalStr) : '',
          'diasRestantes': diasRestantes,
          'progresso': progress,
          'ativo': !concluido && diasRestantes > 0,
          'concluido': concluido,
          'imagem': obj['imagem'],
          'id_badge': badgeId,
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
