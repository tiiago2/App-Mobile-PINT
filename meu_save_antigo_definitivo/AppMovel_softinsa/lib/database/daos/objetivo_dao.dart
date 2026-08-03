import 'dart:async';
import 'dart:convert';
import 'package:sqflite/sqflite.dart';
import '../database_helper.dart';
import '../database_schema.dart';
import '../sync_helpers.dart';
import 'sync_outbox_dao.dart';

class ObjetivosDao {
  ObjetivosDao._();
  static final ObjetivosDao instance = ObjetivosDao._();

  final _changes = StreamController<int>.broadcast();
  Stream<int> get changes => _changes.stream;

  /// Retrieves a specific objective, respecting soft delete 'deleted_objetivo IS NULL'.
  Future<Map<String, dynamic>?> getObjetivo(int localId) async {
    final db = await DatabaseHelper.instance.database;
    final rows = await db.query(
      DatabaseSchema.objetivosTable,
      where: 'id_objetivo_local = ? AND deleted_objetivo IS NULL',
      whereArgs: [localId],
      limit: 1,
    );
    if (rows.isEmpty) return null;
    return rows.first;
  }

  /// Lists all active objectives for a user, respecting 'deleted_objetivo IS NULL'.
  Future<List<Map<String, dynamic>>> getObjetivosDoUtilizador(int userId) async {
    return lerObjetivosDoUtilizador(userId);
  }

  /// Inserts a new local objective.
  Future<int> insertObjetivo(Map<String, dynamic> objetivo) async {
    final db = await DatabaseHelper.instance.database;
    final cleanRow = Map<String, dynamic>.from(objetivo);

    cleanRow.putIfAbsent('data_inicial', () => utcNow());
    cleanRow['local_updated_at'] = utcNow();
    cleanRow.putIfAbsent('sync_status', () => 'pending_insert');
    cleanRow['deleted_objetivo'] = null;

    final localId = await db.insert(
      DatabaseSchema.objetivosTable,
      cleanRow,
      conflictAlgorithm: ConflictAlgorithm.replace,
    );

    _changes.add(cleanRow['id_utilizador'] ?? -1);
    return localId;
  }

  /// Soft deletes an objective.
  Future<void> apagarObjetivo(int localId) async {
    final db = await DatabaseHelper.instance.database;
    final now = utcNow();

    final rows = await db.query(
      DatabaseSchema.objetivosTable,
      columns: ['id_utilizador', 'id_objetivo', 'sync_status'],
      where: 'id_objetivo_local = ?',
      whereArgs: [localId],
      limit: 1,
    );
    if (rows.isEmpty) return;
    final row = rows.first;
    final userId = intOrNull(row['id_utilizador']) ?? -1;
    final remoteIdVal = intOrNull(row['id_objetivo']);

    await db.transaction((txn) async {
      if (row['sync_status'] == 'pending_insert' && remoteIdVal == null) {
        await txn.delete(
          DatabaseSchema.syncOutboxTable,
          where: 'user_id = ? AND entity = ? AND local_record_id = ?',
          whereArgs: [userId, 'objetivos', localId],
        );
        await txn.delete(
          DatabaseSchema.objetivosTable,
          where: 'id_objetivo_local = ?',
          whereArgs: [localId],
        );
        return;
      }

      await txn.update(
        DatabaseSchema.objetivosTable,
        {
          'deleted_objetivo': 1,
          'local_updated_at': now,
          'sync_status': 'pending_delete',
        },
        where: 'id_objetivo_local = ?',
        whereArgs: [localId],
      );

      final clientId = "client_obj_del_${DateTime.now().millisecondsSinceEpoch}";
      await SyncOutboxDao.instance.adicionarOperacaoNoExecutor(
        txn,
        userId: userId,
        entity: 'objetivos',
        operation: 'delete',
        localRecordId: localId,
        clientId: clientId,
        payload: {
          'client_id': clientId,
          'id_objetivo': remoteIdVal,
        },
      );
    });

    _changes.add(userId);
  }

  /// Batch upserts objectives from sync.
  Future<void> upsertFromSync(List<Map<String, dynamic>> dados) async {
    final db = await DatabaseHelper.instance.database;
    await db.transaction((txn) async {
      for (final raw in dados) {
        final idObjetivo = intOrNull(raw['id_objetivo'] ?? raw['remote_id'] ?? raw['id']);
        final idUtilizador = intOrNull(raw['id_utilizador'] ?? raw['utilizador_id'] ?? raw['user_id']);
        final idBadge = intOrNull(raw['id_badge'] ?? raw['badge_id']);

        if (idObjetivo == null || idUtilizador == null || idBadge == null) {
          print('⚠️ [ObjetivosDao] Ignorado devido a chaves nulas: id_objetivo=$idObjetivo, id_utilizador=$idUtilizador, id_badge=$idBadge');
          continue;
        }

        final deletedObjetivo = (raw['deleted_objetivo'] == true || raw['deleted_objetivo'] == 1 || raw['deleted_at'] != null) ? 1 : 0;

        final cleanRow = {
          'id_objetivo': idObjetivo,
          'id_utilizador': idUtilizador,
          'id_badge': idBadge,
          'data_inicial': raw['data_inicial'] ?? utcNow(),
          'data_final': raw['data_final'] ?? raw['data'] ?? utcNow(),
          'data_conclusao': raw['data_conclusao'],
          'badge_json': raw['badge'] is Map ? jsonEncode(raw['badge']) : (raw['badge_json'] ?? '{}'),
          'deleted_objetivo': deletedObjetivo,
          'local_updated_at': utcNow(),
          'updated_objetivo': raw['updated_objetivo']?.toString() ?? raw['server_updated_at']?.toString() ?? raw['updated_at']?.toString(),
          'sync_status': 'synced',
        };

        final existing = await txn.query(
          DatabaseSchema.objetivosTable,
          columns: ['id_objetivo_local'],
          where: 'id_objetivo = ?',
          whereArgs: [idObjetivo],
          limit: 1,
        );

        if (existing.isNotEmpty) {
          await txn.update(
            DatabaseSchema.objetivosTable,
            cleanRow,
            where: 'id_objetivo_local = ?',
            whereArgs: [existing.first['id_objetivo_local']],
          );
        } else {
          await txn.insert(
            DatabaseSchema.objetivosTable,
            cleanRow,
          );
        }
      }
    });
    _changes.add(-1);
  }

  // --- Legacy Compatibility Methods ---

  Future<int> criarObjetivoLocal({
    required int userId,
    required int badgeId,
    required String dataFinal,
    String? titulo,
    String? descricao,
  }) async {
    if (userId <= 0 || DateTime.tryParse(dataFinal) == null) {
      throw Exception('invalid_objective');
    }
    final db = await DatabaseHelper.instance.database;
    final clientId = generateClientId();
    final now = utcNow();
    final localId = await db.transaction((txn) async {
      final id = await txn.insert(DatabaseSchema.objetivosTable, {
        'id_utilizador': userId,
        'id_badge': badgeId,
        'data_inicial': now,
        'data_final': dataFinal,
        'badge_json': '{}',
        'local_updated_at': now,
        'sync_status': 'pending_insert',
      });
      await SyncOutboxDao.instance.adicionarOperacaoNoExecutor(
        txn,
        userId: userId,
        entity: 'objetivos',
        operation: 'insert',
        localRecordId: id,
        clientId: clientId,
        payload: {
          'client_id': clientId,
          'id_badge': badgeId,
          'data_final': dataFinal,
        },
      );
      return id;
    });
    _changes.add(userId);
    return localId;
  }

  /// Atualiza o ID do servidor e o sync_status de um objetivo local.
  Future<void> marcarComoSincronizado(int idLocal, int idServidor, [DatabaseExecutor? executor]) async {
    final db = executor ?? await DatabaseHelper.instance.database;
    await db.update(
      DatabaseSchema.objetivosTable,
      {
        'id_objetivo': idServidor,
        'sync_status': 'synced',
      },
      where: 'id_objetivo_local = ?',
      whereArgs: [idLocal],
    );
    print('✅ [SQLite Update] Objetivo local $idLocal atualizado para ID Servidor $idServidor (sync_status = synced)');
  }

  Future<void> atualizarObjetivoLocal({
    required int userId,
    required int localId,
    String? titulo,
    String? descricao,
    String? dataFinal,
    int? progresso,
    bool? concluido,
  }) async {
    if (userId <= 0 ||
        (dataFinal != null && DateTime.tryParse(dataFinal) == null)) {
      throw Exception('invalid_objective');
    }
    final db = await DatabaseHelper.instance.database;
    await db.transaction((txn) async {
      final rows = await txn.query(
        DatabaseSchema.objetivosTable,
        where: 'local_id = ? AND utilizador_id = ? AND deleted_at IS NULL',
        whereArgs: [localId, userId],
        limit: 1,
      );
      if (rows.isEmpty) throw Exception('objective_not_found');
      final row = rows.first;
      final syncStatus = row['sync_status'] == 'pending_insert'
          ? 'pending_insert'
          : 'pending_update';
      final values = <String, Object?>{
        if (concluido == true) 'data_conclusao': utcNow(),
        'local_updated_at': utcNow(),
        'sync_status': syncStatus,
      };
      if (titulo != null) values['titulo'] = titulo;
      if (descricao != null) values['descricao'] = descricao;
      if (dataFinal != null) values['data_final'] = dataFinal;
      if (progresso != null) values['progresso'] = progresso.clamp(0, 100);
      if (concluido != null) values['concluido'] = concluido ? 1 : 0;
      await txn.update(
        DatabaseSchema.objetivosTable,
        values,
        where: 'local_id = ? AND utilizador_id = ?',
        whereArgs: [localId, userId],
      );
      await SyncOutboxDao.instance.adicionarOperacaoNoExecutor(
        txn,
        userId: userId,
        entity: 'objetivos',
        operation: 'update',
        localRecordId: localId,
        clientId: row['client_id'] as String,
        payload: {...row, ...values},
      );
    });
    _changes.add(userId);
  }

  Future<void> eliminarObjetivoLocal({
    required int userId,
    required int localId,
  }) async {
    final db = await DatabaseHelper.instance.database;
    await db.transaction((txn) async {
      final rows = await txn.query(
        DatabaseSchema.objetivosTable,
        where: 'local_id = ? AND utilizador_id = ?',
        whereArgs: [localId, userId],
        limit: 1,
      );
      if (rows.isEmpty) throw Exception('objective_not_found');
      if (rows.first['sync_status'] == 'pending_insert' &&
          rows.first['remote_id'] == null) {
        await txn.delete(
          DatabaseSchema.syncOutboxTable,
          where: 'user_id = ? AND entity = ? AND local_record_id = ?',
          whereArgs: [userId, 'objetivos', localId],
        );
        await txn.delete(
          DatabaseSchema.objetivosTable,
          where: 'local_id = ? AND utilizador_id = ?',
          whereArgs: [localId, userId],
        );
        return;
      }
      await txn.update(
        DatabaseSchema.objetivosTable,
        {
          'deleted_at': utcNow(),
          'local_updated_at': utcNow(),
          'sync_status': 'pending_delete',
        },
        where: 'local_id = ?',
        whereArgs: [localId],
      );
      await SyncOutboxDao.instance.adicionarOperacaoNoExecutor(
        txn,
        userId: userId,
        entity: 'objetivos',
        operation: 'delete',
        localRecordId: localId,
        clientId: rows.first['client_id'] as String,
        payload: {
          'client_id': rows.first['client_id'],
          'remote_id': rows.first['remote_id'],
        },
      );
    });
    _changes.add(userId);
  }

  Future<List<Map<String, dynamic>>> lerObjetivosDoUtilizador(int userId) async {
    final db = await DatabaseHelper.instance.database;
    final rows = await db.query(
      DatabaseSchema.objetivosTable,
      where: 'id_utilizador = ? AND deleted_objetivo IS NULL',
      whereArgs: [userId],
      orderBy: 'data_final ASC',
    );
    return rows
        .map(
          (row) => {
            ...row,
            'id': row['id_objetivo_local'],
            'id_objetivo': row['id_objetivo_local'],
            'objective_id': row['id_objetivo_local'],
            'id_remoto': row['id_objetivo'],
            'id_badge': row['id_badge'],
            'id_utilizador': row['id_utilizador'],
            'data': row['data_final'],
            if (row['badge_json'] is String)
              'badge': _decodeMap(row['badge_json'] as String),
          },
        )
        .toList(growable: false);
  }

  Future<void> aplicarSnapshotRemoto({
    required int userId,
    required List<Map<String, dynamic>> objetivos,
  }) async {
    final db = await DatabaseHelper.instance.database;
    await db.transaction((txn) async {
      final remoteIds = <int>[];
      for (final raw in objetivos) {
        final remoteId = intOrNull(
          raw['id_objetivo'] ?? raw['id'] ?? raw['remote_id'],
        );
        final badgeId = intOrNull(
          raw['id_badge'] ??
              raw['badge_id'] ??
              (raw['badge'] is Map ? raw['badge']['id_badge'] : null),
        );
        if (remoteId == null || badgeId == null) continue;
        final dataInicial = raw['data_inicial']?.toString();
        final dataFinal = (raw['data_final'] ?? raw['data'])?.toString();
        if (dataInicial == null ||
            dataFinal == null ||
            DateTime.tryParse(dataInicial) == null ||
            DateTime.tryParse(dataFinal) == null) {
          throw Exception('invalid_remote_objective');
        }
        remoteIds.add(remoteId);
        final existing = await txn.query(
          DatabaseSchema.objetivosTable,
          where: 'id_utilizador = ? AND id_objetivo = ?',
          whereArgs: [userId, remoteId],
          limit: 1,
        );
        if (existing.isNotEmpty && existing.first['sync_status'] != 'synced') {
          await txn.update(
            DatabaseSchema.objetivosTable,
            {
              'id_objetivo': remoteId,
              'updated_objetivo': raw['updated_at']?.toString(),
            },
            where: 'id_objetivo_local = ?',
            whereArgs: [existing.first['id_objetivo_local']],
          );
          continue;
        }
        if (existing.isNotEmpty &&
            !remoteVersionIsCurrent(
              raw['updated_at'],
              existing.first['updated_objetivo'],
            )) {
          continue;
        }
        final values = {
          'id_objetivo': remoteId,
          'id_utilizador': userId,
          'id_badge': badgeId,
          'data_inicial': dataInicial,
          'data_final': dataFinal,
          'data_conclusao': raw['data_conclusao']?.toString(),
          'badge_json': raw['badge'] is Map
              ? jsonEncode(raw['badge'])
              : raw['badge_json']?.toString(),
          'deleted_objetivo': raw['deleted_at'] != null || raw['deleted_objetivo'] == 1 ? 1 : 0,
          'local_updated_at': utcNow(),
          'updated_objetivo': raw['updated_at']?.toString(),
          'sync_status': 'synced',
        };
        if (existing.isEmpty) {
          await txn.insert(DatabaseSchema.objetivosTable, values);
        } else {
          await txn.update(
            DatabaseSchema.objetivosTable,
            values,
            where: 'id_objetivo_local = ?',
            whereArgs: [existing.first['id_objetivo_local']],
          );
        }
      }
      final synced = await txn.query(
        DatabaseSchema.objetivosTable,
        columns: ['id_objetivo_local', 'id_objetivo'],
        where: "id_utilizador = ? AND sync_status = 'synced'",
        whereArgs: [userId],
      );
      for (final row in synced) {
        if (!remoteIds.contains(intOrNull(row['id_objetivo']))) {
          await txn.delete(
            DatabaseSchema.objetivosTable,
            where: 'id_objetivo_local = ?',
            whereArgs: [row['id_objetivo_local']],
          );
        }
      }
    });
    _changes.add(userId);
  }

  Map<String, dynamic> _decodeMap(String value) {
    try {
      final decoded = jsonDecode(value);
      return decoded is Map ? Map<String, dynamic>.from(decoded) : {};
    } on FormatException {
      return {};
    }
  }

  /// Apaga fisicamente um objetivo pelo ID do servidor.
  Future<void> apagarFisicamente(int serverId) async {
    final db = await DatabaseHelper.instance.database;
    await db.delete(
      DatabaseSchema.objetivosTable,
      where: 'id_objetivo = ?',
      whereArgs: [serverId],
    );
    _changes.add(-1);
  }

  /// Query A: Obter os Objetivos do Utilizador com info do Badge
  Future<List<Map<String, dynamic>>> obterObjetivosComBadges(int userId) async {
    final db = await DatabaseHelper.instance.database;
    return db.rawQuery('''
      SELECT o.id_objetivo_local, o.id_objetivo, o.data_inicial, o.data_final, o.data_conclusao, o.sync_status,
             b.id_badge, b.nome_badge, b.imagem, b.pontos_badge, a.nome_area as categoria_badge
      FROM ${DatabaseSchema.objetivosTable} o
      INNER JOIN ${DatabaseSchema.badgesTable} b ON o.id_badge = b.id_badge
      LEFT JOIN ${DatabaseSchema.areasTable} a ON b.id_area = a.id_area
      WHERE o.id_utilizador = ? 
        AND (o.deleted_objetivo IS NOT 1) 
        AND (b.deleted_badge IS NOT 1)
    ''', [userId]);
  }

  /// Query B: Obter os Badges Disponíveis para criação de objetivos (exclui conquistados e objetivos ativos)
  Future<List<Map<String, dynamic>>> obterBadgesDisponiveis(int userId) async {
    final db = await DatabaseHelper.instance.database;
    return db.rawQuery('''
      SELECT b.id_badge, b.nome_badge, b.imagem, a.nome_area as categoria_badge
      FROM ${DatabaseSchema.badgesTable} b
      LEFT JOIN ${DatabaseSchema.areasTable} a ON b.id_area = a.id_area
      WHERE (b.deleted_badge IS NOT 1)
        AND b.id_badge NOT IN (
          SELECT rb.id_badge 
          FROM ${DatabaseSchema.registoBadgesTable} rb 
          WHERE rb.id_utilizador = ? AND (rb.deleted_registo IS NOT 1)
        )
        AND b.id_badge NOT IN (
          SELECT o.id_badge 
          FROM ${DatabaseSchema.objetivosTable} o 
          WHERE o.id_utilizador = ? 
            AND o.data_conclusao IS NULL 
            AND (o.deleted_objetivo IS NOT 1)
        )
      ORDER BY b.nome_badge ASC
    ''', [userId, userId]);
  }
}
