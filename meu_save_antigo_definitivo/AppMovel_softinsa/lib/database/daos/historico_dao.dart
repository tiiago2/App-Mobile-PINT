import 'dart:async';
import 'dart:convert';
import 'package:sqflite/sqflite.dart';
import '../database_helper.dart';
import '../database_schema.dart';
import '../sync_helpers.dart';

class HistoricoDao {
  HistoricoDao._internal();
  static final HistoricoDao instance = HistoricoDao._internal();

  final _changes = StreamController<int>.broadcast();
  Stream<int> get changes => _changes.stream;

  /// Retrieves history entries by remote submissao ID.
  Future<List<Map<String, dynamic>>> getHistorico(int idSubmissao) async {
    final db = await DatabaseHelper.instance.database;
    return db.query(
      DatabaseSchema.historicoTable,
      where: 'id_submissao = ?',
      whereArgs: [idSubmissao],
      orderBy: 'data_avaliacao DESC',
    );
  }

  /// Lists history entries for a local submission ID.
  Future<List<Map<String, dynamic>>> getHistoricoDaSubmissao(int submissaoLocalId) async {
    final db = await DatabaseHelper.instance.database;
    
    final sub = await db.query(
      DatabaseSchema.submissoesTable,
      columns: ['id_submissao'],
      where: 'id_submissao_local = ?',
      whereArgs: [submissaoLocalId],
      limit: 1,
    );
    if (sub.isEmpty) return const [];
    final idSubmissao = intOrNull(sub.first['id_submissao']);
    if (idSubmissao == null) return const [];

    return db.query(
      DatabaseSchema.historicoTable,
      where: 'id_submissao = ?',
      whereArgs: [idSubmissao],
      orderBy: 'data_avaliacao DESC',
    );
  }

  /// Batch upserts history from sync.
  Future<void> upsertFromSync(List<Map<String, dynamic>> dados) async {
    final db = await DatabaseHelper.instance.database;
    
    final batch = db.batch();
    for (final raw in dados) {
      final valUser = raw['id_utilizador'] ?? raw['user_id'];
      final idUtilizador = valUser != null ? int.tryParse(valUser.toString()) : null;

      final valSub = raw['id_submissao'] ?? raw['submissao_id'] ?? raw['id_submissao_local'];
      final remoteSubmissaoId = valSub != null ? int.tryParse(valSub.toString()) : null;

      if (idUtilizador == null || remoteSubmissaoId == null) {
        print('⚠️ [HistoricoDao] Ignorado por ID nulo: $raw');
        continue;
      }

      final aceite = (raw['aceite'] == true || raw['aceite'] == 1 || raw['aceite'] == '1') ? 1 : 0;
      final deletedHistorico = (raw['deleted_historico'] == true || raw['deleted_historico'] == 1 || raw['deleted_historico'] == '1') ? 1 : 0;
      final dataAvaliacao = raw['data_avaliacao']?.toString() ?? raw['timestamp_historico']?.toString() ?? utcNow();

      final cleanRow = {
        'id_utilizador': idUtilizador,
        'id_submissao': remoteSubmissaoId,
        'aceite': aceite,
        'data_avaliacao': dataAvaliacao,
        'feedback': raw['feedback']?.toString(),
        'historico_json': raw['historico_json'] ?? jsonEncode(raw),
        'updated_historico': raw['updated_historico']?.toString() ?? raw['server_updated_at']?.toString() ?? raw['updated_at']?.toString(),
        'deleted_historico': deletedHistorico,
      };

      batch.insert(
        DatabaseSchema.historicoTable,
        cleanRow,
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
    }
    await batch.commit(noResult: true);
    _changes.add(-1);
  }

  /// Retrieves history entries for a specific user.
  Future<List<Map<String, dynamic>>> lerHistoricoDoUtilizador(int userId) async {
    final db = await DatabaseHelper.instance.database;
    return db.rawQuery(
      '''
      SELECT h.*
      FROM ${DatabaseSchema.historicoTable} h
      JOIN ${DatabaseSchema.submissoesTable} s ON s.id_submissao = h.id_submissao
      WHERE s.id_utilizador = ? AND s.deleted_submissao IS NULL
      ORDER BY h.data_avaliacao DESC
    ''',
      [userId],
    );
  }
}
