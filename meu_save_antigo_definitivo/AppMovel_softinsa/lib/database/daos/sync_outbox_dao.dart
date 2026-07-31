import 'dart:convert';
import 'package:sqflite/sqflite.dart';
import '../database_helper.dart';
import '../database_schema.dart';
import '../sync_helpers.dart';

class SyncOutboxDao {
  static final SyncOutboxDao instance = SyncOutboxDao._();
  SyncOutboxDao._();

  /// Adiciona uma operação pendente de sincronização.
  Future<void> adicionarOperacao({
    required int userId,
    required String entity,
    required String operation,
    required int localRecordId,
    required String clientId,
    required Map<String, dynamic> payload,
  }) async {
    final db = await DatabaseHelper.instance.database;
    await _processarAdicionarOperacao(
      db,
      userId: userId,
      entity: entity,
      operation: operation,
      localRecordId: localRecordId,
      clientId: clientId,
      payload: payload,
    );
  }

  /// Adiciona uma operação pendente dentro de um executor (ex: transação).
  Future<void> adicionarOperacaoNoExecutor(
    DatabaseExecutor executor, {
    required int userId,
    required String entity,
    required String operation,
    required int localRecordId,
    required String clientId,
    required Map<String, dynamic> payload,
  }) async {
    await _processarAdicionarOperacao(
      executor,
      userId: userId,
      entity: entity,
      operation: operation,
      localRecordId: localRecordId,
      clientId: clientId,
      payload: payload,
    );
  }

  Future<void> _processarAdicionarOperacao(
    DatabaseExecutor executor, {
    required int userId,
    required String entity,
    required String operation,
    required int localRecordId,
    required String clientId,
    required Map<String, dynamic> payload,
  }) async {
    final now = utcNow();

    if (operation == 'update') {
      final existingInsert = await executor.query(
        DatabaseSchema.syncOutboxTable,
        where: 'user_id = ? AND entity = ? AND local_record_id = ? AND operation = ? AND status = ?',
        whereArgs: [userId, entity, localRecordId, 'insert', 'pending'],
        limit: 1,
      );
      if (existingInsert.isNotEmpty) {
        final existingId = existingInsert.first['id'] as String;
        Map<String, dynamic> existingPayload = {};
        try {
          final decoded = jsonDecode(existingInsert.first['payload'] as String);
          if (decoded is Map) {
            existingPayload = Map<String, dynamic>.from(decoded);
          }
        } catch (_) {}
        
        final mergedPayload = <String, dynamic>{
          ...existingPayload,
          ...payload,
        };

        await executor.update(
          DatabaseSchema.syncOutboxTable,
          <String, dynamic>{
            'payload': jsonEncode(mergedPayload),
            'created_at': now,
          },
          where: 'id = ?',
          whereArgs: [existingId],
        );
        return;
      }
    }

    await executor.insert(
      DatabaseSchema.syncOutboxTable,
      <String, dynamic>{
        'id': generateClientId(),
        'user_id': userId,
        'entity': entity,
        'operation': operation,
        'local_record_id': localRecordId,
        'client_id': clientId,
        'payload': jsonEncode(payload),
        'created_at': now,
        'status': 'pending',
        'attempts': 0,
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  /// Lê as operações pendentes de um utilizador.
  Future<List<Map<String, dynamic>>> lerPendentes(int userId) async {
    final db = await DatabaseHelper.instance.database;
    return db.query(
      DatabaseSchema.syncOutboxTable,
      where: 'user_id = ? AND status = ?',
      whereArgs: [userId, 'pending'],
      orderBy: 'created_at ASC',
    );
  }

  /// Marca uma operação como concluída.
  Future<void> marcarComoConcluida(String id) async {
    final db = await DatabaseHelper.instance.database;
    await db.update(
      DatabaseSchema.syncOutboxTable,
      <String, dynamic>{'status': 'completed'},
      where: 'id = ?',
      whereArgs: [id],
    );
  }
}
