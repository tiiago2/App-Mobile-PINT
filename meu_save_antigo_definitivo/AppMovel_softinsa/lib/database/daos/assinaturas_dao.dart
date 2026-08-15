import 'dart:async';
import 'dart:convert';
import '../database_helper.dart';
import '../database_schema.dart';
import '../sync_helpers.dart';
import 'sync_outbox_dao.dart';

class AssinaturasDao {
  AssinaturasDao._internal();
  static final AssinaturasDao instance = AssinaturasDao._internal();

  final _changes = StreamController<int>.broadcast();
  Stream<int> get changes => _changes.stream;

  /// Retrieves a specific signature by remote ID.
  Future<Map<String, dynamic>?> getAssinatura(int idAssinatura) async {
    final db = await DatabaseHelper.instance.database;
    final rows = await db.query(
      DatabaseSchema.assinaturaTable,
      where: 'id_assinatura = ?',
      whereArgs: [idAssinatura],
      limit: 1,
    );
    if (rows.isEmpty) return null;
    return rows.first;
  }

  /// Retrieves a signature by the owner's user ID.
  Future<Map<String, dynamic>?> getAssinaturaPorProprietario(int idProprietario) async {
    final db = await DatabaseHelper.instance.database;
    final rows = await db.query(
      DatabaseSchema.assinaturaTable,
      where: 'id_proprietario = ?',
      whereArgs: [idProprietario],
      limit: 1,
    );
    if (rows.isEmpty) return null;
    return rows.first;
  }

  /// Batch upserts signatures from sync.
  Future<void> upsertFromSync(List<Map<String, dynamic>> records) async {
    final db = await DatabaseHelper.instance.database;
    await db.transaction((txn) async {
      for (final raw in records) {
        final idAssinatura = intOrNull(raw['id_assinatura'] ?? raw['id']);
        final idProprietario = intOrNull(raw['id_proprietario'] ?? raw['proprietario_id'] ?? raw['user_id'] ?? raw['id_utilizador']);

        if (idAssinatura == null || idProprietario == null) {
          print('⚠️ [AssinaturasDao] Ignorado devido a chaves nulas: id_assinatura=$idAssinatura, id_proprietario=$idProprietario');
          continue;
        }

        final existing = await txn.query(
          DatabaseSchema.assinaturaTable,
          columns: ['id_assinatura_local'],
          where: 'id_proprietario = ?',
          whereArgs: [idProprietario],
          limit: 1,
        );

        final values = {
          'id_assinatura': idAssinatura,
          'id_proprietario': idProprietario,
          'assinatura_json': raw['assinatura_json'] ?? jsonEncode(raw),
          'update_assinatura': raw['update_assinatura']?.toString(),
          'local_updated_at': DateTime.now().toIso8601String(),
          'server_updated_at': raw['updated_at']?.toString() ?? raw['criado_em']?.toString(),
          'sync_status': 'synced',
        };

        if (existing.isNotEmpty) {
          await txn.update(
            DatabaseSchema.assinaturaTable,
            values,
            where: 'id_proprietario = ?',
            whereArgs: [idProprietario],
          );
        } else {
          await txn.insert(
            DatabaseSchema.assinaturaTable,
            values,
          );
        }
      }
    });
    _changes.add(-1);
  }

  /// Salva ou atualiza uma assinatura local e a regista na Outbox.
  Future<int> guardarAssinaturaLocal({
    required int userId,
    required Map<String, dynamic> assinatura,
  }) async {
    final db = await DatabaseHelper.instance.database;
    final now = DateTime.now().toIso8601String();
    
    final existing = await db.query(
      DatabaseSchema.assinaturaTable,
      columns: ['id_assinatura_local', 'id_assinatura', 'sync_status'],
      where: 'id_proprietario = ?',
      whereArgs: [userId],
      limit: 1,
    );

    final clientId = assinatura['client_id']?.toString() ?? "client_sig_${DateTime.now().millisecondsSinceEpoch}";
    int localId;

    if (existing.isEmpty) {
      localId = await db.transaction((txn) async {
        final id = await txn.insert(
          DatabaseSchema.assinaturaTable,
          {
            'id_proprietario': userId,
            'assinatura_json': jsonEncode({...assinatura, 'client_id': clientId}),
            'local_updated_at': now,
            'sync_status': 'pending_insert',
          },
        );

        await SyncOutboxDao.instance.adicionarOperacaoNoExecutor(
          txn,
          userId: userId,
          entity: 'assinatura',
          operation: 'insert',
          localRecordId: id,
          clientId: clientId,
          payload: {
            'client_id': clientId,
            'id_proprietario': userId,
            'dados_assinatura': assinatura['dados_assinatura'],
            'formato': assinatura['formato'],
            'data_assinatura': assinatura['data_assinatura'],
          },
        );
        return id;
      });
    } else {
      final row = existing.first;
      localId = row['id_assinatura_local'] as int;
      final currentSync = row['sync_status'] as String;
      final remoteId = row['id_assinatura'] as int?;

      await db.transaction((txn) async {
        await txn.update(
          DatabaseSchema.assinaturaTable,
          {
            'assinatura_json': jsonEncode({...assinatura, 'client_id': clientId}),
            'local_updated_at': now,
            'sync_status': currentSync == 'pending_insert' ? 'pending_insert' : 'pending_update',
          },
          where: 'id_assinatura_local = ?',
          whereArgs: [localId],
        );

        final op = currentSync == 'pending_insert' ? 'insert' : 'update';

        await SyncOutboxDao.instance.adicionarOperacaoNoExecutor(
          txn,
          userId: userId,
          entity: 'assinatura',
          operation: op,
          localRecordId: localId,
          clientId: clientId,
          payload: {
            'client_id': clientId,
            'id_assinatura': remoteId,
            'id_proprietario': userId,
            'dados_assinatura': assinatura['dados_assinatura'],
            'formato': assinatura['formato'],
            'data_assinatura': assinatura['data_assinatura'],
          },
        );
      });
    }

    _changes.add(userId);
    return localId;
  }

  /// Query 2: Obter os IDs de badges associados à assinatura do utilizador
  Future<List<int>> obterIdsBadgesAssinatura(int userId) async {
    final db = await DatabaseHelper.instance.database;
    final rows = await db.rawQuery('''
      SELECT ba.id_badge
      FROM ${DatabaseSchema.badgesAssinaturaTable} ba
      INNER JOIN ${DatabaseSchema.assinaturaTable} a ON ba.id_assinatura_local = a.id_assinatura_local
      INNER JOIN ${DatabaseSchema.registoBadgesTable} rb ON rb.id_badge = ba.id_badge AND rb.id_utilizador = a.id_proprietario
      WHERE a.id_proprietario = ?
        AND (rb.expirado IS NOT 1 AND rb.expirado != 1)
        AND (rb.deleted_registo IS NOT 1)
    ''', [userId]);

    return rows.map((row) => row['id_badge'] as int).toList();
  }

  /// Confirma a sincronização de assinaturas em lote após push sync com sucesso.
  Future<void> confirmarSincronizacaoEmLote(Map<dynamic, dynamic> mapaIds) async {
    final db = await DatabaseHelper.instance.database;
    final batch = db.batch();

    mapaIds.forEach((tempId, realId) {
      final tId = intOrNull(tempId);
      final rId = intOrNull(realId);
      if (tId != null && rId != null) {
        batch.update(
          DatabaseSchema.assinaturaTable,
          {
            'id_assinatura': rId,
            'sync_status': 'synced',
            'local_updated_at': DateTime.now().toIso8601String(),
          },
          where: 'id_assinatura_local = ? OR id_proprietario = ?',
          whereArgs: [tId, tId],
        );
      }
    });

    await batch.commit(noResult: true);
    _changes.add(-1);
  }
}
