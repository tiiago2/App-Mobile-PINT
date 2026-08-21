import 'dart:async';
import 'package:sqflite/sqflite.dart';
import '../database_helper.dart';
import '../database_schema.dart';
import '../sync_helpers.dart';

class SubmissaoRequisitosDao {
  SubmissaoRequisitosDao._();
  static final SubmissaoRequisitosDao instance = SubmissaoRequisitosDao._();

  final _changes = StreamController<int>.broadcast();
  Stream<int> get changes => _changes.stream;

  /// Retrieves requirement progress details.
  Future<Map<String, dynamic>?> getSubmissaoRequisito(int submissaoLocalId, int requisitoId) async {
    final db = await DatabaseHelper.instance.database;
    final rows = await db.query(
      DatabaseSchema.submissaoRequisitosTable,
      where: 'id_submissao_local = ? AND id_requisito = ? AND (deleted_at = 0 OR deleted_at IS NULL)',
      whereArgs: [submissaoLocalId, requisitoId],
      limit: 1,
    );
    if (rows.isEmpty) return null;
    return rows.first;
  }

  /// Lists all requirement progress details for a submission.
  Future<List<Map<String, dynamic>>> getRequisitosDaSubmissao(int submissaoLocalId) async {
    final db = await DatabaseHelper.instance.database;
    return db.query(
      DatabaseSchema.submissaoRequisitosTable,
      where: 'id_submissao_local = ? AND (deleted_at = 0 OR deleted_at IS NULL)',
      whereArgs: [submissaoLocalId],
    );
  }

  /// Inserts a new requirement progress record.
  Future<void> insertSubmissaoRequisito(Map<String, dynamic> record) async {
    final db = await DatabaseHelper.instance.database;
    final cleanRow = Map<String, dynamic>.from(record);
    
    cleanRow.putIfAbsent('estado_local', () => 'pending');
    cleanRow.putIfAbsent('local_updated_at', () => utcNow());
    cleanRow.putIfAbsent('deleted_at', () => null);

    await db.insert(
      DatabaseSchema.submissaoRequisitosTable,
      cleanRow,
      conflictAlgorithm: ConflictAlgorithm.replace,
    );

    _changes.add(cleanRow['id_submissao_local'] ?? -1);
  }

  /// Updates the progress of a requirement (e.g. changing estado_local).
  Future<void> updateSubmissaoRequisito(int submissaoLocalId, int requisitoId, String estadoLocal) async {
    final db = await DatabaseHelper.instance.database;
    final now = utcNow();

    await db.update(
      DatabaseSchema.submissaoRequisitosTable,
      {
        'estado_local': estadoLocal,
        'local_updated_at': now,
      },
      where: 'id_submissao_local = ? AND id_requisito = ?',
      whereArgs: [submissaoLocalId, requisitoId],
    );

    _changes.add(submissaoLocalId);
  }

  /// Batch upserts requirement progress from server sync.
  Future<void> upsertFromSync(List<Map<String, dynamic>> dados) async {
    final db = await DatabaseHelper.instance.database;
    
    // Fetch all submissions to verify they exist locally and map remote_id -> local_id (Regra 4)
    final submissoes = await db.query(
      DatabaseSchema.submissoesTable,
      columns: ['id_submissao_local', 'id_submissao'],
    );
    final Map<int, int> remoteToLocalMap = {};
    for (final row in submissoes) {
      final remoteId = row['id_submissao'] as int?;
      final localId = row['id_submissao_local'] as int?;
      if (remoteId != null && localId != null) {
        remoteToLocalMap[remoteId] = localId;
      }
    }

    final batch = db.batch();
    for (final raw in dados) {
      final remoteSubmissaoId = intOrNull(raw['id_submissao'] ?? raw['submissao_id'] ?? raw['submissao_local_id']);
      final idRequisito = intOrNull(raw['id_requisito'] ?? raw['requisito_id']);

      if (remoteSubmissaoId == null || idRequisito == null) {
        print('⚠️ [SubmissaoRequisitosDao] Ignorado devido a chaves nulas: id_submissao=$remoteSubmissaoId, id_requisito=$idRequisito');
        continue;
      }

      final idSubmissaoLocal = remoteToLocalMap[remoteSubmissaoId];
      if (idSubmissaoLocal == null) {
        print('⚠️ [SubmissaoRequisitosDao] Ignorado: submissão local não encontrada para id_submissao remoto: $remoteSubmissaoId');
        continue;
      }

      batch.insert(
        DatabaseSchema.submissaoRequisitosTable,
        {
          'id_submissao_local': idSubmissaoLocal,
          'id_requisito': idRequisito,
          'estado_local': raw['estado_local'] ?? 'pending',
          'estado_remoto': raw['estado_remoto'],
          'local_updated_at': raw['local_updated_at']?.toString() ?? utcNow(),
          'server_updated_at': raw['server_updated_at']?.toString() ?? raw['updated_at']?.toString(),
          'deleted_at': raw['deleted_at']?.toString(),
        },
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
    }
    await batch.commit(noResult: true);
    _changes.add(-1);
  }
}
