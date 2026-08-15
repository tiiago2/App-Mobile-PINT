import 'dart:async';
import 'package:sqflite/sqflite.dart';
import '../database_helper.dart';
import '../database_schema.dart';
import '../sync_helpers.dart';
import 'sync_outbox_dao.dart';

class DocumentosSubmissaoDao {
  DocumentosSubmissaoDao._internal();
  static final DocumentosSubmissaoDao instance = DocumentosSubmissaoDao._internal();

  final _changes = StreamController<int>.broadcast();
  Stream<int> get changes => _changes.stream;

  /// Retrieves a specific document by local_id.
  Future<Map<String, dynamic>?> getDocumento(int localId) async {
    final db = await DatabaseHelper.instance.database;
    final rows = await db.query(
      DatabaseSchema.documentosSubmissaoTable,
      where: 'id_ficheiro_local = ? AND deleted_file IS NULL',
      whereArgs: [localId],
      limit: 1,
    );
    if (rows.isEmpty) return null;
    return rows.first;
  }

  /// Lists all active documents linked to a submission.
  Future<List<Map<String, dynamic>>> getDocumentosDaSubmissao(int submissaoLocalId) async {
    final db = await DatabaseHelper.instance.database;
    return db.query(
      DatabaseSchema.documentosSubmissaoTable,
      where: 'id_submissao_local = ? AND deleted_file IS NULL',
      whereArgs: [submissaoLocalId],
    );
  }

  /// Inserts a new local document.
  Future<int> insertDocumento(Map<String, dynamic> documento) async {
    final db = await DatabaseHelper.instance.database;
    final cleanRow = Map<String, dynamic>.from(documento);

    final subLocalId = intOrNull(cleanRow['id_submissao_local'] ?? cleanRow['submissao_local_id']);
    final reqId = intOrNull(cleanRow['id_requisito'] ?? cleanRow['requisito_id']);

    final normalized = {
      'id_ficheiro': intOrNull(cleanRow['id_ficheiro'] ?? cleanRow['remote_id']),
      'id_submissao_local': subLocalId ?? -1,
      'id_submissao': intOrNull(cleanRow['id_submissao'] ?? cleanRow['remote_submissao_id']),
      'id_requisito': reqId ?? -1,
      'ficheiro': cleanRow['ficheiro'] ?? cleanRow['nome_ficheiro'] ?? cleanRow['url_remota'],
      'ficheiro_local': cleanRow['ficheiro_local'] ?? cleanRow['caminho_local'],
      'tamanho_bytes': intOrNull(cleanRow['tamanho_bytes']),
      'hash_ficheiro': cleanRow['hash_ficheiro'],
      'upload_status': cleanRow['upload_status'] ?? 'rascunho',
      'upload_error': cleanRow['upload_error'],
      'updated_file': cleanRow['updated_file'] ?? cleanRow['server_updated_at'] ?? cleanRow['updated_at'],
      'created_local_at': cleanRow['created_local_at'] ?? utcNow(),
      'synced_at': cleanRow['synced_at'],
      'sync_status': cleanRow['sync_status'] ?? 'pending_insert',
      'deleted_file': (cleanRow['deleted_file'] == true || cleanRow['deleted_file'] == 1) ? 1 : 0,
    };

    final localId = await db.insert(
      DatabaseSchema.documentosSubmissaoTable,
      normalized,
      conflictAlgorithm: ConflictAlgorithm.replace,
    );

    int? userId = intOrNull(cleanRow['id_utilizador'] ?? cleanRow['user_id']);
    int? idServidorReal;
    if (subLocalId != null && subLocalId > 0) {
      final subRows = await db.query(
        DatabaseSchema.submissoesTable,
        where: 'id_submissao_local = ?',
        whereArgs: [subLocalId],
        limit: 1,
      );
      if (subRows.isNotEmpty) {
        userId ??= intOrNull(subRows.first['id_utilizador']);
        idServidorReal = intOrNull(
          subRows.first['id_submissao'] ??
          subRows.first['id_servidor'] ??
          subRows.first['id_submissao_servidor']
        );
      }
    }

    if (normalized['sync_status'] == 'pending_insert' && userId != null && userId > 0) {
      final clientId = cleanRow['client_id']?.toString() ?? "client_doc_${DateTime.now().millisecondsSinceEpoch}";
      await SyncOutboxDao.instance.adicionarOperacao(
        userId: userId,
        entity: 'documentos_submissao',
        operation: 'insert',
        localRecordId: localId,
        clientId: clientId,
        payload: {
          'client_id': clientId,
          'id_submissao': idServidorReal,
          'id_submissao_local': subLocalId,
          'id_requisito': reqId,
          'url_ficheiro': normalized['ficheiro_local'],
          'nome_ficheiro': normalized['ficheiro'],
        },
      );
    }

    _changes.add(subLocalId ?? -1);
    return localId;
  }

  /// Atualiza o ID do servidor e o sync_status de um documento local.
  Future<void> marcarComoSincronizado(int idLocal, int idServidor, [DatabaseExecutor? executor]) async {
    final db = executor ?? await DatabaseHelper.instance.database;
    await db.update(
      DatabaseSchema.documentosSubmissaoTable,
      {
        'id_ficheiro': idServidor,
        'sync_status': 'synced',
      },
      where: 'id_ficheiro_local = ?',
      whereArgs: [idLocal],
    );
    print('✅ [SQLite Update] Documento local $idLocal atualizado para ID Servidor $idServidor (sync_status = synced)');
  }

  /// Updates an existing document (e.g. changing upload_status).
  Future<void> updateDocumento(Map<String, dynamic> documento) async {
    final db = await DatabaseHelper.instance.database;
    final localId = documento['id_ficheiro_local'] ?? documento['local_id'];
    if (localId == null) {
      throw Exception('id_ficheiro_local ou local_id é obrigatório para update.');
    }

    final cleanRow = Map<String, dynamic>.from(documento);
    final existing = await getDocumento(localId);
    if (existing != null) {
      final currentSync = existing['sync_status'];
      if (currentSync != 'pending_insert') {
        cleanRow['sync_status'] = 'pending_update';
      }
    }

    final normalized = {
      if (cleanRow.containsKey('id_ficheiro') || cleanRow.containsKey('remote_id'))
        'id_ficheiro': intOrNull(cleanRow['id_ficheiro'] ?? cleanRow['remote_id']),
      if (cleanRow.containsKey('id_submissao_local') || cleanRow.containsKey('submissao_local_id'))
        'id_submissao_local': intOrNull(cleanRow['id_submissao_local'] ?? cleanRow['submissao_local_id']),
      if (cleanRow.containsKey('id_submissao') || cleanRow.containsKey('remote_submissao_id'))
        'id_submissao': intOrNull(cleanRow['id_submissao'] ?? cleanRow['remote_submissao_id']),
      if (cleanRow.containsKey('id_requisito') || cleanRow.containsKey('requisito_id'))
        'id_requisito': intOrNull(cleanRow['id_requisito'] ?? cleanRow['requisito_id']),
      if (cleanRow.containsKey('ficheiro') || cleanRow.containsKey('nome_ficheiro'))
        'ficheiro': cleanRow['ficheiro'] ?? cleanRow['nome_ficheiro'],
      if (cleanRow.containsKey('ficheiro_local') || cleanRow.containsKey('caminho_local'))
        'ficheiro_local': cleanRow['ficheiro_local'] ?? cleanRow['caminho_local'],
      if (cleanRow.containsKey('tamanho_bytes'))
        'tamanho_bytes': intOrNull(cleanRow['tamanho_bytes']),
      if (cleanRow.containsKey('hash_ficheiro'))
        'hash_ficheiro': cleanRow['hash_ficheiro'],
      if (cleanRow.containsKey('upload_status'))
        'upload_status': cleanRow['upload_status'],
      if (cleanRow.containsKey('upload_error'))
        'upload_error': cleanRow['upload_error'],
      if (cleanRow.containsKey('updated_file'))
        'updated_file': cleanRow['updated_file'],
      if (cleanRow.containsKey('created_local_at'))
        'created_local_at': cleanRow['created_local_at'],
      if (cleanRow.containsKey('synced_at'))
        'synced_at': cleanRow['synced_at'],
      if (cleanRow.containsKey('sync_status'))
        'sync_status': cleanRow['sync_status'],
      if (cleanRow.containsKey('deleted_file') || cleanRow.containsKey('deleted_at'))
        'deleted_file': (cleanRow['deleted_file'] == true || cleanRow['deleted_file'] == 1 || cleanRow['deleted_at'] != null) ? 1 : 0,
    };

    await db.update(
      DatabaseSchema.documentosSubmissaoTable,
      normalized,
      where: 'id_ficheiro_local = ?',
      whereArgs: [localId],
    );

    int? userId = intOrNull(cleanRow['id_utilizador'] ?? cleanRow['user_id']);
    final subLocalId = intOrNull(normalized['id_submissao_local'] ?? (existing != null ? existing['id_submissao_local'] : null));
    int? idServidorReal;
    if (subLocalId != null && subLocalId > 0) {
      final subRows = await db.query(
        DatabaseSchema.submissoesTable,
        where: 'id_submissao_local = ?',
        whereArgs: [subLocalId],
        limit: 1,
      );
      if (subRows.isNotEmpty) {
        userId ??= intOrNull(subRows.first['id_utilizador']);
        idServidorReal = intOrNull(
          subRows.first['id_submissao'] ??
          subRows.first['id_servidor'] ??
          subRows.first['id_submissao_servidor']
        );
      }
    }

    if (userId != null && userId > 0) {
      final syncStatus = normalized['sync_status'] ?? (existing != null ? existing['sync_status'] : null);
      if (syncStatus == 'pending_insert' || syncStatus == 'pending_update') {
        final op = syncStatus == 'pending_insert' ? 'insert' : 'update';
        final clientId = cleanRow['client_id']?.toString() ?? "client_doc_${DateTime.now().millisecondsSinceEpoch}";
        final docFicheiro = normalized['ficheiro'] ?? (existing != null ? existing['ficheiro'] : null);
        final docFicheiroLocal = normalized['ficheiro_local'] ?? (existing != null ? existing['ficheiro_local'] : null);
        final docReqId = normalized['id_requisito'] ?? (existing != null ? existing['id_requisito'] : null);
        final remoteIdVal = intOrNull(normalized['id_ficheiro'] ?? (existing != null ? existing['id_ficheiro'] : null));

        await SyncOutboxDao.instance.adicionarOperacao(
          userId: userId,
          entity: 'documentos_submissao',
          operation: op,
          localRecordId: localId,
          clientId: clientId,
          payload: {
            'client_id': clientId,
            'id_ficheiro': remoteIdVal,
            'id_submissao': idServidorReal,
            'id_submissao_local': subLocalId,
            'id_requisito': docReqId,
            'url_ficheiro': docFicheiroLocal,
            'nome_ficheiro': docFicheiro,
          },
        );
      }
    }

    _changes.add(intOrNull(cleanRow['id_submissao_local'] ?? cleanRow['submissao_local_id']) ?? -1);
  }

  /// Batch upserts documents from sync.
  Future<void> upsertFromSync(List<Map<String, dynamic>> dados) async {
    final db = await DatabaseHelper.instance.database;

    // Fetch all submissions to verify they exist locally and map remote_id -> local_id
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

    await db.transaction((txn) async {
      for (final raw in dados) {
        final valFich = raw['id_ficheiro'] ?? raw['id_documento'] ?? raw['remote_id'] ?? raw['id'];
        final idFicheiro = valFich != null ? int.tryParse(valFich.toString()) : null;

        final valReq = raw['id_requisito'] ?? raw['requisito_id'];
        final idRequisito = valReq != null ? int.tryParse(valReq.toString()) : null;

        final valSub = raw['id_submissao'] ?? raw['submissao_id'];
        final remoteSubmissaoId = valSub != null ? int.tryParse(valSub.toString()) : null;

        if (idFicheiro == null || idRequisito == null || remoteSubmissaoId == null) {
          print('⚠️ [DocumentosSubmissaoDao] Ignorado por ID nulo: $raw');
          continue;
        }

        final idSubmissaoLocal = remoteToLocalMap[remoteSubmissaoId];
        if (idSubmissaoLocal == null) {
          print('⚠️ [DocumentosSubmissaoDao] Ignorado: submissão local não encontrada para id_submissao remoto: $remoteSubmissaoId');
          continue;
        }

        final deletedFile = (raw['deleted_file'] == true || raw['deleted_file'] == 1 || raw['deleted_at'] != null) ? 1 : 0;

        final existing = await txn.query(
          DatabaseSchema.documentosSubmissaoTable,
          columns: ['id_ficheiro_local'],
          where: 'id_ficheiro = ?',
          whereArgs: [idFicheiro],
          limit: 1,
        );

        final values = {
          'id_ficheiro': idFicheiro,
          'id_submissao_local': idSubmissaoLocal,
          'id_submissao': remoteSubmissaoId,
          'id_requisito': idRequisito,
          'ficheiro': raw['ficheiro']?.toString() ?? raw['url_remota']?.toString() ?? raw['nome_ficheiro']?.toString(),
          'ficheiro_local': raw['ficheiro_local']?.toString() ?? raw['caminho_local']?.toString(),
          'url_ficheiro': raw['url_ficheiro']?.toString() ?? raw['ficheiro']?.toString() ?? raw['url_remota']?.toString(),
          'tamanho_bytes': intOrNull(raw['tamanho_bytes'] ?? raw['file_size']),
          'hash_ficheiro': raw['hash_ficheiro']?.toString() ?? raw['file_hash']?.toString(),
          'upload_status': raw['upload_status']?.toString() ?? 'completed',
          'upload_error': raw['upload_error']?.toString(),
          'updated_file': raw['updated_file']?.toString() ?? raw['server_updated_at']?.toString() ?? raw['updated_at']?.toString(),
          'created_local_at': raw['created_local_at']?.toString() ?? raw['created_at']?.toString() ?? utcNow(),
          'synced_at': raw['synced_at']?.toString() ?? utcNow(),
          'sync_status': 'synced',
          'deleted_file': deletedFile,
        };

        if (existing.isNotEmpty) {
          await txn.update(
            DatabaseSchema.documentosSubmissaoTable,
            values,
            where: 'id_ficheiro_local = ?',
            whereArgs: [existing.first['id_ficheiro_local']],
          );
        } else {
          await txn.insert(
            DatabaseSchema.documentosSubmissaoTable,
            values,
          );
        }
      }
    });
    _changes.add(-1);
  }

  /// Apaga um documento localmente de forma inteligente.
  Future<void> apagarDocumento({
    required int userId,
    required int localId,
  }) async {
    final db = await DatabaseHelper.instance.database;
    await db.transaction((txn) async {
      final rows = await txn.query(
        DatabaseSchema.documentosSubmissaoTable,
        where: 'id_ficheiro_local = ?',
        whereArgs: [localId],
        limit: 1,
      );
      if (rows.isEmpty) throw Exception('documento_not_found');
      final row = rows.first;
      final serverId = intOrNull(row['id_ficheiro']);
      
      if (serverId == null) {
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
      } else {
        await txn.update(
          DatabaseSchema.documentosSubmissaoTable,
          {'deleted_file': 1, 'sync_status': 'pending_delete'},
          where: 'id_ficheiro_local = ?',
          whereArgs: [localId],
        );
        
        final clientId = "client_doc_del_${DateTime.now().millisecondsSinceEpoch}";
        await SyncOutboxDao.instance.adicionarOperacaoNoExecutor(
          txn,
          userId: userId,
          entity: 'documentos_submissao',
          operation: 'delete',
          localRecordId: localId,
          clientId: clientId,
          payload: {
            'client_id': clientId,
            'id': serverId,
            'id_ficheiro': serverId,
          },
        );
      }
    });
    _changes.add(userId);
  }
}
