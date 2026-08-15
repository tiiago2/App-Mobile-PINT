import 'package:flutter/foundation.dart';
import 'dart:async';
import 'dart:convert';
import 'package:sqflite/sqflite.dart';
import '../database_helper.dart';
import '../database_schema.dart';
import '../sync_helpers.dart';
import 'sync_outbox_dao.dart';

class SubmissoesDao {
  SubmissoesDao._();
  static final SubmissoesDao instance = SubmissoesDao._();

  final _changes = StreamController<int>.broadcast();
  Stream<int> get changes => _changes.stream;

  /// Retrieves a specific submission by local_id, filtering deleted rows.
  Future<Map<String, dynamic>?> getSubmissao(int localId) async {
    final db = await DatabaseHelper.instance.database;
    final rows = await db.query(
      DatabaseSchema.submissoesTable,
      where: 'id_submissao_local = ? AND (deleted_submissao = 0 OR deleted_submissao IS NULL OR deleted_submissao = "false" OR deleted_submissao = "0")',
      whereArgs: [localId],
      limit: 1,
    );
    if (rows.isEmpty) return null;
    return rows.first;
  }

  /// Inserts a new submission local record, returning local_id.
  Future<int> insertSubmissao(Map<String, dynamic> submissao) async {
    final db = await DatabaseHelper.instance.database;
    final cleanRow = Map<String, dynamic>.from(submissao);
    
    // Normalize keys to strictly match the new table columns
    final userId = intOrNull(cleanRow['id_utilizador'] ?? cleanRow['user_id']);
    final badgeId = intOrNull(cleanRow['id_badge'] ?? cleanRow['badge_id']);
    
    final normalizedRow = {
      'id_submissao': intOrNull(cleanRow['id_submissao'] ?? cleanRow['remote_id']),
      'id_utilizador': userId ?? -1,
      'id_badge': badgeId ?? -1,
      'status': cleanRow['status'] ?? 'em_progresso',
      'remote_status': cleanRow['remote_status'],
      'data_criacao': cleanRow['data_criacao'] ?? utcNow(),
      'data_submissao': cleanRow['data_submissao'],
      'submissao_json': cleanRow['submissao_json'],
      'local_updated_at': utcNow(),
      'updated_submissao': cleanRow['updated_submissao'] ?? cleanRow['server_updated_at'],
      'sync_status': cleanRow['sync_status'] ?? 'pending_insert',
      'deleted_submissao': (cleanRow['deleted_submissao'] == true || cleanRow['deleted_submissao'] == 1 || cleanRow['deleted_submissao'] == 'true' || cleanRow['deleted_submissao'] == '1') ? 1 : 0,
    };

    int localId = await db.insert(
      DatabaseSchema.submissoesTable,
      normalizedRow,
      conflictAlgorithm: ConflictAlgorithm.ignore,
    );

    if (localId == 0 || localId == -1) {
      // Já existe um registo com o mesmo id_submissao, fazemos update em vez de replace para não disparar CASCADE DELETE
      final idSubmissao = normalizedRow['id_submissao'];
      if (idSubmissao != null) {
        await db.update(
          DatabaseSchema.submissoesTable,
          normalizedRow,
          where: 'id_submissao = ?',
          whereArgs: [idSubmissao],
        );
        final existing = await db.query(
          DatabaseSchema.submissoesTable,
          columns: ['id_submissao_local'],
          where: 'id_submissao = ?',
          whereArgs: [idSubmissao],
          limit: 1,
        );
        if (existing.isNotEmpty) {
          localId = existing.first['id_submissao_local'] as int;
        }
      }
    }
    
    _changes.add(userId ?? -1);
    return localId;
  }

  /// Updates an existing submission record to modify local status.
  Future<void> updateSubmissao(Map<String, dynamic> submissao) async {
    final db = await DatabaseHelper.instance.database;
    final localId = submissao['id_submissao_local'] ?? submissao['local_id'];
    if (localId == null) {
      throw Exception('local_id ou id_submissao_local Ã© obrigatÃ³rio para update.');
    }
    
    final cleanRow = Map<String, dynamic>.from(submissao);
    cleanRow['local_updated_at'] = utcNow();
    
    final existing = await getSubmissao(localId);
    if (existing != null) {
      final currentSync = existing['sync_status'];
      if (currentSync != 'pending_insert') {
        cleanRow['sync_status'] = 'pending_update';
      }
    }

    // Normalize keys
    final normalizedRow = {
      if (cleanRow.containsKey('id_submissao') || cleanRow.containsKey('remote_id'))
        'id_submissao': intOrNull(cleanRow['id_submissao'] ?? cleanRow['remote_id']),
      if (cleanRow.containsKey('id_utilizador') || cleanRow.containsKey('user_id'))
        'id_utilizador': intOrNull(cleanRow['id_utilizador'] ?? cleanRow['user_id']),
      if (cleanRow.containsKey('id_badge') || cleanRow.containsKey('badge_id'))
        'id_badge': intOrNull(cleanRow['id_badge'] ?? cleanRow['badge_id']),
      if (cleanRow.containsKey('status'))
        'status': cleanRow['status'],
      if (cleanRow.containsKey('remote_status'))
        'remote_status': cleanRow['remote_status'],
      if (cleanRow.containsKey('data_criacao'))
        'data_criacao': cleanRow['data_criacao'],
      if (cleanRow.containsKey('data_submissao'))
        'data_submissao': cleanRow['data_submissao'],
      if (cleanRow.containsKey('submissao_json'))
        'submissao_json': cleanRow['submissao_json'],
      'local_updated_at': cleanRow['local_updated_at'],
      if (cleanRow.containsKey('updated_submissao') || cleanRow.containsKey('server_updated_at'))
        'updated_submissao': cleanRow['updated_submissao'] ?? cleanRow['server_updated_at'],
      if (cleanRow.containsKey('sync_status'))
        'sync_status': cleanRow['sync_status'],
      if (cleanRow.containsKey('deleted_submissao') || cleanRow.containsKey('deleted_at'))
        'deleted_submissao': ((cleanRow['deleted_submissao'] ?? cleanRow['deleted_at']) == true || (cleanRow['deleted_submissao'] ?? cleanRow['deleted_at']) == 1 || (cleanRow['deleted_submissao'] ?? cleanRow['deleted_at']) == 'true' || (cleanRow['deleted_submissao'] ?? cleanRow['deleted_at']) == '1') ? 1 : 0,
    };

    await db.update(
      DatabaseSchema.submissoesTable,
      normalizedRow,
      where: 'id_submissao_local = ?',
      whereArgs: [localId],
    );

    _changes.add(intOrNull(cleanRow['id_utilizador'] ?? cleanRow['user_id']) ?? -1);
  }

  /// Batch upserts submissions from server sync.
  Future<void> upsertFromSync(List<Map<String, dynamic>> dados) async {
    debugPrint('ðŸ“¥ [SubmissoesDao] upsertFromSync chamado com ${dados.length} registos vindos do servidor.');
    final db = await DatabaseHelper.instance.database;
    int gravadosComSucesso = 0;
    int ignorados = 0;

    await db.transaction((txn) async {
      for (final raw in dados) {
        try {
          final remoteId = intOrNull(raw['id_submissao'] ?? raw['remote_id'] ?? raw['id']);
          final userId = intOrNull(raw['id_utilizador'] ?? raw['user_id']);
          final badgeId = intOrNull(raw['id_badge'] ?? raw['badge_id']);

          if (remoteId == null || userId == null || badgeId == null) {
            debugPrint('âš ï¸ [SubmissoesDao] Ignorado por chaves nulas: id_submissao=$remoteId (original: ${raw['id_submissao'] ?? raw['id']}), id_utilizador=$userId (original: ${raw['id_utilizador'] ?? raw['user_id']}), id_badge=$badgeId (original: ${raw['id_badge'] ?? raw['badge_id']})');
            ignorados++;
            continue;
          }

          final cleanRow = {
            'id_submissao': remoteId,
            'id_utilizador': userId,
            'id_badge': badgeId,
            'status': raw['status'] ?? 'em_progresso',
            'remote_status': raw['remote_status'] ?? raw['status'],
            'data_criacao': raw['data_criacao'] ?? raw['created_at'] ?? utcNow(),
            'data_submissao': raw['data_submissao'],
            'submissao_json': raw['submissao_json'] ?? jsonEncode(raw),
            'local_updated_at': utcNow(),
            'updated_submissao': raw['updated_submissao'] ?? raw['server_updated_at'] ?? raw['updated_at']?.toString(),
            'sync_status': 'synced',
            'deleted_submissao': (raw['deleted_submissao'] == true || raw['deleted_submissao'] == 1 || raw['deleted_submissao'] == 'true' || raw['deleted_submissao'] == '1') ? 1 : 0,
          };

          // 1. Check if there's an existing submission with this server ID
          final existingByRemote = await txn.query(
            DatabaseSchema.submissoesTable,
            columns: ['id_submissao_local'],
            where: 'id_submissao = ?',
            whereArgs: [remoteId],
            limit: 1,
          );

          if (existingByRemote.isNotEmpty) {
            await txn.update(
              DatabaseSchema.submissoesTable,
              cleanRow,
              where: 'id_submissao_local = ?',
              whereArgs: [existingByRemote.first['id_submissao_local']],
            );
          } else {
            // 2. Otherwise, check if there's a local pending insertion (id_submissao is NULL) for the same user/badge
            final pendingLocal = await txn.query(
              DatabaseSchema.submissoesTable,
              columns: ['id_submissao_local'],
              where: 'id_utilizador = ? AND id_badge = ? AND id_submissao IS NULL',
              whereArgs: [userId, badgeId],
              limit: 1,
            );

            if (pendingLocal.isNotEmpty) {
              await txn.update(
                DatabaseSchema.submissoesTable,
                cleanRow,
                where: 'id_submissao_local = ?',
                whereArgs: [pendingLocal.first['id_submissao_local']],
              );
              debugPrint('ðŸ”— [SubmissoesDao] Vinculado registo local pendente ${pendingLocal.first['id_submissao_local']} ao id_submissao servidor $remoteId');
            } else {
              // 3. Otherwise, insert a new record
              await txn.insert(
                DatabaseSchema.submissoesTable,
                cleanRow,
              );
            }
          }
          gravadosComSucesso++;
        } catch (e, stack) {
          debugPrint('âŒ [SubmissoesDao] Erro ao gravar submissÃ£o (remoteId: ${raw['id_submissao'] ?? raw['remote_id'] ?? raw['id']}): $e');
          debugPrint(stack.toString());
          rethrow;
        }
      }
    });

    debugPrint('ðŸ’¾ [SubmissoesDao] Fim do upsertFromSync: $gravadosComSucesso gravados/atualizados com sucesso, $ignorados ignorados.');
    _changes.add(-1);
  }

  // --- Legacy Compatibility Methods ---

  Future<int> obterOuCriarRascunhoLocal({required int idBadge, required int userId}) async {
    final db = await DatabaseHelper.instance.database;

    // Procura se já existe rascunho local ativo para o badge
    final existentes = await db.query(
      DatabaseSchema.submissoesTable,
      where: 'id_badge = ? AND id_utilizador = ? AND (status = "em_progresso" OR status = "rascunho" OR status = "draft" OR status = "emprogresso") AND (deleted_submissao = 0 OR deleted_submissao IS NULL OR deleted_submissao = "false" OR deleted_submissao = "0")',
      whereArgs: [idBadge, userId],
      orderBy: 'id_submissao_local DESC',
      limit: 1,
    );

    if (existentes.isNotEmpty) {
      return existentes.first['id_submissao_local'] as int;
    }

    // Cria novo apenas se não existir
    return await criarRascunhoLocal(
      userId: userId,
      badgeId: idBadge,
    );
  }

  Future<int> criarRascunhoLocal({
    required int userId,
    required int badgeId,
  }) async {
    if (userId <= 0) throw Exception('invalid_user');
    final db = await DatabaseHelper.instance.database;
    final recordClientId = generateClientId();
    final now = utcNow();
    final localId = await db.transaction((txn) async {
      final id = await txn.insert(DatabaseSchema.submissoesTable, {
        'id_utilizador': userId,
        'id_badge': badgeId,
        'status': 'em_progresso',
        'data_criacao': now,
        'local_updated_at': now,
        'sync_status': 'pending_insert',
      });
      await SyncOutboxDao.instance.adicionarOperacaoNoExecutor(
        txn,
        userId: userId,
        entity: 'submissoes',
        operation: 'insert',
        localRecordId: id,
        clientId: recordClientId,
        payload: {
          'client_id': recordClientId,
          'id_badge': badgeId,
          'status': 'em_progresso',
        },
      );
      return id;
    });
    _changes.add(userId);
    return localId;
  }

  /// Reconcilia o ID local com o ID do servidor e atualiza os anexos correspondentes.
  Future<void> reconciliarIdServidor(int tempLocalId, int realServerId, [DatabaseExecutor? executor]) async {
    final db = executor ?? await DatabaseHelper.instance.database;

    Future<void> action(DatabaseExecutor ex) async {
      // Evitar erros UNIQUE: se já existe alguma linha antiga com o mesmo id_submissao remoto, removemo-la
      await ex.delete(
        DatabaseSchema.submissoesTable,
        where: 'id_submissao = ? AND id_submissao_local != ?',
        whereArgs: [realServerId, tempLocalId],
      );

      await ex.update(
        DatabaseSchema.submissoesTable,
        {
          'id_submissao': realServerId,
          'sync_status': 'synced',
          'local_updated_at': utcNow(),
        },
        where: 'id_submissao_local = ?',
        whereArgs: [tempLocalId],
      );

      await ex.update(
        DatabaseSchema.documentosSubmissaoTable,
        {
          'id_submissao': realServerId,
          'sync_status': 'synced',
        },
        where: 'id_submissao_local = ?',
        whereArgs: [tempLocalId],
      );
    }

    if (executor != null) {
      await action(executor);
    } else {
      await (db as Database).transaction((txn) async {
        await action(txn);
      });
    }

    debugPrint('✅ [SubmissoesDao] Reconciliado ID local $tempLocalId para Servidor $realServerId e atualizados anexos.');
    _changes.add(-1);
  }

  /// MantÃ©m assinatura antiga por retrocompatibilidade de chamadas legadas
  Future<void> marcarComoSincronizado(int idLocal, int idServidor, [DatabaseExecutor? executor]) async {
    await reconciliarIdServidor(idLocal, idServidor, executor);
  }

  Future<void> atualizarEstadoLocal({
    required int userId,
    required int localId,
    required String estado,
  }) async {
    final db = await DatabaseHelper.instance.database;
    await db.transaction((txn) async {
      final rows = await txn.query(
        DatabaseSchema.submissoesTable,
        where: 'id_submissao_local = ? AND id_utilizador = ? AND (deleted_submissao = 0 OR deleted_submissao IS NULL OR deleted_submissao = "false" OR deleted_submissao = "0")',
        whereArgs: [localId, userId],
        limit: 1,
      );
      if (rows.isEmpty) throw Exception('submission_not_found');
      if (_estadoFinal(rows.first['status']?.toString())) {
        throw Exception('submission_final_state');
      }
      final currentSync = rows.first['sync_status']?.toString();
      await txn.update(
        DatabaseSchema.submissoesTable,
        {
          'status': estado,
          'local_updated_at': utcNow(),
          'sync_status': currentSync == 'pending_insert'
              ? 'pending_insert'
              : 'pending_update',
        },
        where: 'id_submissao_local = ?',
        whereArgs: [localId],
      );

      String? clientId;
      try {
        final json = jsonDecode(rows.first['submissao_json']?.toString() ?? '{}');
        clientId = json['client_id']?.toString();
      } catch (_) {}
      clientId ??= generateClientId();

      final remoteIdVal = intOrNull(rows.first['id_submissao'] ?? rows.first['remote_id']);

      await SyncOutboxDao.instance.adicionarOperacaoNoExecutor(
        txn,
        userId: userId,
        entity: 'submissoes',
        operation: 'update',
        localRecordId: localId,
        clientId: clientId,
        payload: {
          'client_id': clientId,
          'id_submissao': remoteIdVal,
          'status': estado,
        },
      );
    });
    _changes.add(userId);
  }

  Future<void> eliminarSubmissaoLocal({
    required int userId,
    required int localId,
  }) async {
    final db = await DatabaseHelper.instance.database;
    await db.transaction((txn) async {
      final rows = await txn.query(
        DatabaseSchema.submissoesTable,
        where: 'id_submissao_local = ? AND id_utilizador = ?',
        whereArgs: [localId, userId],
        limit: 1,
      );
      if (rows.isEmpty) throw Exception('submission_not_found');
      if (_estadoFinal(rows.first['status']?.toString())) {
        throw Exception('submission_final_state');
      }

      final remoteIdVal = intOrNull(rows.first['id_submissao'] ?? rows.first['remote_id']);
      String? clientId;
      try {
        final json = jsonDecode(rows.first['submissao_json']?.toString() ?? '{}');
        clientId = json['client_id']?.toString();
      } catch (_) {}
      clientId ??= generateClientId();

      if (rows.first['sync_status'] == 'pending_insert' &&
          remoteIdVal == null) {
        await txn.rawDelete(
          '''
          DELETE FROM ${DatabaseSchema.syncOutboxTable}
          WHERE user_id = ?
            AND entity = 'documentos_submissao'
            AND local_record_id IN (
              SELECT id_ficheiro_local
              FROM ${DatabaseSchema.documentosSubmissaoTable}
              WHERE id_submissao_local = ?
            )
          ''',
          [userId, localId],
        );
        await txn.delete(
          DatabaseSchema.syncOutboxTable,
          where: 'user_id = ? AND entity = ? AND local_record_id = ?',
          whereArgs: [userId, 'submissoes', localId],
        );
        await txn.delete(
          DatabaseSchema.submissoesTable,
          where: 'id_submissao_local = ? AND id_utilizador = ?',
          whereArgs: [localId, userId],
        );
        return;
      }
      await txn.update(
        DatabaseSchema.submissoesTable,
        {
          'deleted_submissao': utcNow(),
          'sync_status': 'pending_delete',
          'local_updated_at': utcNow(),
        },
        where: 'id_submissao_local = ?',
        whereArgs: [localId],
      );
      await SyncOutboxDao.instance.adicionarOperacaoNoExecutor(
        txn,
        userId: userId,
        entity: 'submissoes',
        operation: 'delete',
        localRecordId: localId,
        clientId: clientId,
        payload: {
          'client_id': clientId,
          'remote_id': remoteIdVal,
        },
      );
    });
    _changes.add(userId);
  }

  Future<void> pedirSubmissaoLocal({
    required int userId,
    required int localId,
    String? comentario,
  }) async {
    final db = await DatabaseHelper.instance.database;
    await db.transaction((txn) async {
      final rows = await txn.query(
        DatabaseSchema.submissoesTable,
        where: 'id_submissao_local = ? AND id_utilizador = ? AND (deleted_submissao = 0 OR deleted_submissao IS NULL OR deleted_submissao = "false" OR deleted_submissao = "0")',
        whereArgs: [localId, userId],
        limit: 1,
      );
      if (rows.isEmpty) throw Exception('submission_not_found');
      final row = rows.first;
      if (_estadoFinal(row['status']?.toString())) {
        throw Exception('submission_final_state');
      }
      final now = utcNow();
      
      final subJsonMap = Map<String, dynamic>.from(
        jsonDecode(row['submissao_json']?.toString() ?? '{}')
      );
      subJsonMap['comentario'] = comentario;
      final recordClientId = subJsonMap['client_id']?.toString() ?? generateClientId();
      final remoteIdVal = intOrNull(row['id_submissao']);

      await txn.update(
        DatabaseSchema.submissoesTable,
        {
          'status': 'pendente',
          'submissao_json': jsonEncode(subJsonMap),
          'data_submissao': now,
          'local_updated_at': now,
          'sync_status': row['sync_status'] == 'pending_insert'
              ? 'pending_insert'
              : 'pending_update',
        },
        where: 'id_submissao_local = ? AND id_utilizador = ?',
        whereArgs: [localId, userId],
      );
      await SyncOutboxDao.instance.adicionarOperacaoNoExecutor(
        txn,
        userId: userId,
        entity: 'submissoes',
        operation: 'submit',
        localRecordId: localId,
        clientId: recordClientId,
        payload: {
          'client_id': recordClientId,
          'id_submissao': remoteIdVal,
          'status': 'pendente',
          'comentario': comentario,
          'data_submissao': now,
          'submit_requested': true,
        },
      );
    });
    _changes.add(userId);
  }

  Future<List<Map<String, dynamic>>> lerSubmissoesDoUtilizador(
    int userId,
  ) async {
    final db = await DatabaseHelper.instance.database;
    return db.rawQuery(
      '''
      SELECT s.*,
             s.id_submissao_local AS submissao_id,
             b.nome_badge AS badge_titulo,
             a.nome_area AS badge_area,
             b.pontos_badge AS badge_pontos,
             b.imagem AS badge_imagem,
             b.id_nivel AS nivelId,
             n.nome_nivel AS nivelNome,
             sl.id_service_line AS serviceLineId,
             sl.nome_service_line AS serviceLineNome,
             lp.id_learning_path AS learningPathId,
             lp.nome_learning_path AS learningPathNome,
             b.especial AS especial,
             (SELECT feedback FROM ${DatabaseSchema.historicoTable} h
              WHERE h.id_submissao = s.id_submissao
              ORDER BY h.data_avaliacao DESC LIMIT 1) AS feedback,
             (SELECT data_avaliacao FROM ${DatabaseSchema.historicoTable} h
              WHERE h.id_submissao = s.id_submissao
              ORDER BY h.data_avaliacao DESC LIMIT 1) AS timestamp_historico
      FROM ${DatabaseSchema.submissoesTable} s
      JOIN ${DatabaseSchema.badgesTable} b ON b.id_badge = s.id_badge
      LEFT JOIN ${DatabaseSchema.areasTable} a ON b.id_area = a.id_area
      LEFT JOIN ${DatabaseSchema.niveisTable} n ON b.id_nivel = n.id_nivel
      LEFT JOIN ${DatabaseSchema.serviceLinesTable} sl ON a.id_service_line = sl.id_service_line
      LEFT JOIN ${DatabaseSchema.learningPathsTable} lp ON sl.id_learning_path = lp.id_learning_path
      WHERE s.id_utilizador = ? AND (s.deleted_submissao = 0 OR s.deleted_submissao IS NULL OR s.deleted_submissao = "false" OR s.deleted_submissao = "0")
      ORDER BY s.local_updated_at DESC
    ''',
      [userId],
    );
  }

  Future<Map<String, dynamic>?> lerSubmissaoCompletaLocal({
    required int userId,
    required int localId,
  }) async {
    final db = await DatabaseHelper.instance.database;
    final rows = await db.rawQuery(
      '''
      SELECT s.*, s.id_submissao_local AS submissao_id,
             b.nome_badge AS badge_titulo, a.nome_area AS badge_area,
             b.pontos_badge AS badge_pontos, b.imagem AS badge_imagem
      FROM ${DatabaseSchema.submissoesTable} s
      JOIN ${DatabaseSchema.badgesTable} b ON b.id_badge = s.id_badge
      LEFT JOIN ${DatabaseSchema.areasTable} a ON a.id_area = CAST(b.id_area AS TEXT)
      WHERE s.id_submissao_local = ? AND s.id_utilizador = ?
      LIMIT 1
    ''',
      [localId, userId],
    );
    if (rows.isEmpty) return null;
    
    final idSubmissao = rows.first['id_submissao'];
    final List<Map<String, dynamic>> historicoRows = idSubmissao != null
        ? await db.query(
            DatabaseSchema.historicoTable,
            where: 'id_submissao = ?',
            whereArgs: [idSubmissao],
            orderBy: 'data_avaliacao DESC',
          )
        : [];

    return {
      'dados_gerais': rows.first,
      'documentos': await listarDocumentosDaSubmissao(
        userId: userId,
        submissaoLocalId: localId,
      ),
      'historico': historicoRows,
    };
  }

  Future<int> guardarDocumentoLocal({
    required int userId,
    required int submissaoLocalId,
    required int requisitoId,
    required String caminhoLocal,
    String? nomeFicheiro,
    String? mimeType,
  }) async {
    final db = await DatabaseHelper.instance.database;
    final recordClientId = generateClientId();
    final localId = await db.transaction((txn) async {
      final owner = await txn.query(
        DatabaseSchema.submissoesTable,
        columns: ['id_submissao_local', 'id_submissao'],
        where: 'id_submissao_local = ? AND id_utilizador = ? AND (deleted_submissao = 0 OR deleted_submissao IS NULL OR deleted_submissao = "false" OR deleted_submissao = "0")',
        whereArgs: [submissaoLocalId, userId],
        limit: 1,
      );
      if (owner.isEmpty) throw Exception('submission_not_found');
      final int? idServidorReal = intOrNull(owner.first['id_submissao']);

      final existing = await txn.query(
        DatabaseSchema.documentosSubmissaoTable,
        where:
            'id_submissao_local = ? AND id_requisito = ? AND ficheiro_local = ? AND (deleted_file = 0 OR deleted_file IS NULL)',
        whereArgs: [submissaoLocalId, requisitoId, caminhoLocal],
        limit: 1,
      );
      if (existing.isNotEmpty) {
        final row = existing.first;
        final existingId = row['id_ficheiro_local'] as int;
        await txn.update(
          DatabaseSchema.documentosSubmissaoTable,
          {
            'ficheiro': nomeFicheiro,
            'sync_status': row['sync_status'] == 'pending_insert'
                ? 'pending_insert'
                : 'pending_update',
          },
          where: 'id_ficheiro_local = ?',
          whereArgs: [existingId],
        );
        await SyncOutboxDao.instance.adicionarOperacaoNoExecutor(
          txn,
          userId: userId,
          entity: 'documentos_submissao',
          operation: 'upload',
          localRecordId: existingId,
          clientId: recordClientId,
          payload: {
            'client_id': recordClientId,
            'id_submissao': idServidorReal,
            'id_submissao_local': submissaoLocalId,
            'id_requisito': requisitoId,
            'url_ficheiro': caminhoLocal,
            'nome_ficheiro': nomeFicheiro,
          },
        );
        return existingId;
      }
      final id = await txn.insert(DatabaseSchema.documentosSubmissaoTable, {
        'id_submissao_local': submissaoLocalId,
        'id_requisito': requisitoId,
        'ficheiro': nomeFicheiro,
        'ficheiro_local': caminhoLocal,
        'tamanho_bytes': 1024,
        'created_local_at': utcNow(),
        'sync_status': 'pending_insert',
      });
      await SyncOutboxDao.instance.adicionarOperacaoNoExecutor(
        txn,
        userId: userId,
        entity: 'documentos_submissao',
        operation: 'upload',
        localRecordId: id,
        clientId: recordClientId,
        payload: {
          'client_id': recordClientId,
          'id_submissao': idServidorReal,
          'id_submissao_local': submissaoLocalId,
          'id_requisito': requisitoId,
          'url_ficheiro': caminhoLocal,
          'nome_ficheiro': nomeFicheiro,
        },
      );
      return id;
    });
    _changes.add(userId);
    return localId;
  }

  Future<List<Map<String, dynamic>>> listarDocumentosDaSubmissao({
    required int userId,
    required int submissaoLocalId,
  }) async {
    final db = await DatabaseHelper.instance.database;
    return db.rawQuery(
      '''
      SELECT d.* FROM ${DatabaseSchema.documentosSubmissaoTable} d
      JOIN ${DatabaseSchema.submissoesTable} s ON s.id_submissao_local = d.id_submissao_local
      WHERE s.id_utilizador = ? AND d.id_submissao_local = ? AND (d.deleted_file = 0 OR d.deleted_file IS NULL)
      ORDER BY d.created_local_at ASC
    ''',
      [userId, submissaoLocalId],
    );
  }

  Future<void> marcarDocumentoParaEliminacao({
    required int userId,
    required int localId,
  }) async {
    final db = await DatabaseHelper.instance.database;
    await db.transaction((txn) async {
      final rows = await txn.rawQuery(
        '''
        SELECT d.* FROM ${DatabaseSchema.documentosSubmissaoTable} d
        JOIN ${DatabaseSchema.submissoesTable} s ON s.id_submissao_local = d.id_submissao_local
        WHERE d.id_ficheiro_local = ? AND s.id_utilizador = ? LIMIT 1
      ''',
        [localId, userId],
      );
      if (rows.isEmpty) throw Exception('document_not_found');
      final row = rows.first;
      if (row['sync_status'] == 'pending_insert' &&
          row['id_ficheiro'] == null) {
        await txn.delete(
          DatabaseSchema.syncOutboxTable,
          where: 'user_id = ? AND entity = ? AND local_record_id = ?',
          whereArgs: [userId, 'documentos_submissao', localId],
        );
        await txn.delete(
          DatabaseSchema.documentosSubmissaoTable,
          where: 'id_ficheiro_local = ?',
          whereArgs: [localId],
        );
        return;
      }
      await txn.update(
        DatabaseSchema.documentosSubmissaoTable,
        {'deleted_file': 1, 'sync_status': 'pending_delete'},
        where: 'id_ficheiro_local = ?',
        whereArgs: [localId],
      );
      
      final clientDelId = "client_doc_del_${DateTime.now().millisecondsSinceEpoch}";
      await SyncOutboxDao.instance.adicionarOperacaoNoExecutor(
        txn,
        userId: userId,
        entity: 'documentos_submissao',
        operation: 'delete',
        localRecordId: localId,
        clientId: clientDelId,
        payload: {
          'client_id': clientDelId,
          'id_ficheiro': row['id_ficheiro'],
        },
      );
    });
    _changes.add(userId);
  }

  Future<void> aplicarSnapshotRemoto({
    required int userId,
    required List<Map<String, dynamic>> submissoes,
  }) async {
    final db = await DatabaseHelper.instance.database;
    await db.transaction((txn) async {
      final remoteIds = <int>[];
      for (final raw in submissoes) {
        final remoteId = intOrNull(
          raw['id_submissao'] ?? raw['remote_id'] ?? raw['id'],
        );
        final badgeId = intOrNull(raw['id_badge'] ?? raw['badge_id']);
        if (remoteId == null || badgeId == null) continue;
        remoteIds.add(remoteId);
        final existing = await txn.query(
          DatabaseSchema.submissoesTable,
          where: 'id_utilizador = ? AND id_submissao = ?',
          whereArgs: [userId, remoteId],
          limit: 1,
        );
        final remoteStatus = raw['status']?.toString() ?? 'em_progresso';
        int localId;
        if (existing.isNotEmpty && existing.first['sync_status'] != 'synced') {
          localId = existing.first['id_submissao_local'] as int;
          await txn.update(
            DatabaseSchema.submissoesTable,
            {
              'id_submissao': remoteId,
              'updated_submissao': (raw['updated_at'] ?? raw['data_submissao'])?.toString(),
            },
            where: 'id_submissao_local = ?',
            whereArgs: [localId],
          );
        } else {
          final remoteCreatedAt =
              (raw['data_criacao'] ??
                      raw['created_at'] ??
                      raw['data_submissao'])
                  ?.toString();
          if (remoteCreatedAt == null ||
              DateTime.tryParse(remoteCreatedAt) == null) {
            throw Exception('invalid_remote_submission');
          }
          if (existing.isNotEmpty &&
              !remoteVersionIsCurrent(
                raw['updated_at'] ?? raw['data_submissao'],
                existing.first['updated_submissao'],
              )) {
            continue;
          }
          final values = {
            'id_submissao': remoteId,
            'id_utilizador': userId,
            'id_badge': badgeId,
            'status': remoteStatus,
            'remote_status': raw['remote_status'] ?? remoteStatus,
            'data_criacao': remoteCreatedAt,
            'data_submissao': raw['data_submissao']?.toString(),
            'submissao_json': jsonEncode(raw),
            'local_updated_at': utcNow(),
            'updated_submissao': (raw['updated_at'] ?? raw['data_submissao'])?.toString(),
            'sync_status': 'synced',
            'deleted_submissao': raw['deleted_submissao']?.toString(),
          };
          if (existing.isEmpty) {
            localId = await txn.insert(DatabaseSchema.submissoesTable, values);
          } else {
            localId = existing.first['id_submissao_local'] as int;
            await txn.update(
              DatabaseSchema.submissoesTable,
              values,
              where: 'id_submissao_local = ?',
              whereArgs: [localId],
            );
          }
        }
        await _aplicarDocumentosRemotos(txn, localId, raw['documentos']);
        // Historico: tentar mÃºltiplas chaves possÃ­veis que a API pode usar dentro da submissÃ£o
        final historicoAninhado = raw['historico'] ??
            raw['historico_candidatura'] ??
            raw['historicos'] ??
            raw['candidatura_historico'] ??
            raw['avaliacoes'];
        await _aplicarHistoricoRemoto(txn, localId, historicoAninhado);
      }
      final synced = await txn.query(
        DatabaseSchema.submissoesTable,
        columns: ['id_submissao_local', 'id_submissao'],
        where: "id_utilizador = ? AND sync_status = 'synced'",
        whereArgs: [userId],
      );
      for (final row in synced) {
        if (!remoteIds.contains(intOrNull(row['id_submissao']))) {
          await txn.delete(
            DatabaseSchema.submissoesTable,
            where: 'id_submissao_local = ?',
            whereArgs: [row['id_submissao_local']],
          );
        }
      }
    });
    _changes.add(userId);
  }

  Future<void> _aplicarDocumentosRemotos(
    DatabaseExecutor txn,
    int submissionLocalId,
    Object? value,
  ) async {
    if (value is! List) return;
    for (final item in value) {
      if (item is! Map) continue;
      final raw = Map<String, dynamic>.from(item);
      final remoteId = intOrNull(
        raw['id_documento'] ?? raw['id_ficheiro'] ?? raw['remote_id'],
      );
      final requisitoId = intOrNull(raw['requisito_id'] ?? raw['id_requisito']);
      if (remoteId == null || requisitoId == null) continue;
      final existing = await txn.query(
        DatabaseSchema.documentosSubmissaoTable,
        where: 'id_submissao_local = ? AND id_ficheiro = ?',
        whereArgs: [submissionLocalId, remoteId],
        limit: 1,
      );
      if (existing.isNotEmpty && existing.first['sync_status'] != 'synced') {
        await txn.update(
          DatabaseSchema.documentosSubmissaoTable,
          {
            'id_ficheiro': remoteId,
            'ficheiro': raw['url_remota'] ?? raw['ficheiro'],
          },
          where: 'id_ficheiro_local = ?',
          whereArgs: [existing.first['id_ficheiro_local']],
        );
        continue;
      }
      final remoteCreatedAt =
          (raw['created_at'] ?? raw['updated_file'] ?? raw['synced_at'])
              ?.toString();
      if (remoteCreatedAt == null ||
          DateTime.tryParse(remoteCreatedAt) == null) {
        throw Exception('invalid_remote_document');
      }
      final values = {
        'id_ficheiro': remoteId,
        'id_submissao_local': submissionLocalId,
        'id_requisito': requisitoId,
        'ficheiro': (raw['url_remota'] ?? raw['ficheiro'] ?? raw['nome_ficheiro'])?.toString(),
        'ficheiro_local': existing.isNotEmpty
            ? existing.first['ficheiro_local']
            : null,
        'created_local_at': remoteCreatedAt,
        'synced_at': (raw['synced_at'] ?? raw['updated_file'])?.toString(),
        'sync_status': 'synced',
        'deleted_file': (raw['deleted_file'] == true || raw['deleted_file'] == 1 || raw['deleted_at'] != null) ? 1 : 0,
      };
      if (existing.isEmpty) {
        await txn.insert(DatabaseSchema.documentosSubmissaoTable, values);
      } else {
        await txn.update(
          DatabaseSchema.documentosSubmissaoTable,
          values,
          where: 'id_ficheiro_local = ?',
          whereArgs: [existing.first['id_ficheiro_local']],
        );
      }
    }
  }

  Future<void> _aplicarHistoricoRemoto(
    DatabaseExecutor txn,
    int submissionLocalId,
    Object? value,
  ) async {
    if (value is! List) return;
    
    final submissoes = await txn.query(
      DatabaseSchema.submissoesTable,
      columns: ['id_submissao'],
      where: 'id_submissao_local = ?',
      whereArgs: [submissionLocalId],
      limit: 1,
    );
    if (submissoes.isEmpty) return;
    final idSubmissao = submissoes.first['id_submissao'] as int?;
    if (idSubmissao == null) return;

    await txn.delete(
      DatabaseSchema.historicoTable,
      where: 'id_submissao = ?',
      whereArgs: [idSubmissao],
    );
    for (final item in value) {
      if (item is! Map) continue;
      final raw = Map<String, dynamic>.from(item);
      final idUtilizador = intOrNull(raw['id_utilizador'] ?? raw['user_id']);
      if (idUtilizador == null) continue;

      final aceite = (raw['aceite'] == true || raw['aceite'] == 1) ? 1 : 0;
      final deletedHistorico = (raw['deleted_historico'] == true || raw['deleted_historico'] == 1) ? 1 : 0;
      final dataAvaliacao = raw['data_avaliacao']?.toString() ?? raw['timestamp_historico']?.toString() ?? DateTime.now().toUtc().toIso8601String();

      await txn.insert(
        DatabaseSchema.historicoTable,
        {
          'id_utilizador': idUtilizador,
          'id_submissao': idSubmissao,
          'aceite': aceite,
          'data_avaliacao': dataAvaliacao,
          'feedback': raw['feedback']?.toString(),
          'historico_json': jsonEncode(raw),
          'updated_historico': raw['updated_historico']?.toString() ?? raw['server_updated_at']?.toString() ?? raw['updated_at']?.toString(),
          'deleted_historico': deletedHistorico,
        },
      );
    }
  }

  Future<void> limparFicheirosConfirmados(int userId) async {
    if (userId <= 0) throw Exception('invalid_user');
  }

  bool _estadoFinal(String? status) {
    final normalized = status?.trim().toLowerCase().replaceAll(' ', '_');
    return const {
      'aprovado',
      'aprovada',
      'reprovado',
      'reprovada',
      'aceite',
      'cancelado',
      'cancelada',
      'cancelado_pelo_sistema',
      'concluido',
      'concluÃ­do',
    }.contains(normalized);
  }

  /// Apaga fisicamente uma submissÃ£o pelo ID do servidor.
  Future<void> apagarFisicamente(int serverId) async {
    final db = await DatabaseHelper.instance.database;
    await db.delete(
      DatabaseSchema.submissoesTable,
      where: 'id_submissao = ?',
      whereArgs: [serverId],
    );
    _changes.add(-1);
  }
}

typedef SubmissaoDao = SubmissoesDao;


