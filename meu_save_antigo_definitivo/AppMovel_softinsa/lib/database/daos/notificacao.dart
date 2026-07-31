import 'dart:async';
import 'package:sqflite/sqflite.dart';
import '../database_helper.dart';
import '../database_schema.dart';
import '../sync_helpers.dart';

class NotificacoesDao {
  NotificacoesDao._internal();
  static final NotificacoesDao instance = NotificacoesDao._internal();

  final _changes = StreamController<int>.broadcast();
  Stream<int> get changes => _changes.stream;

  /// Retrieves list of notifications for the user.
  Future<List<Map<String, dynamic>>> getNotificacoes() async {
    final db = await DatabaseHelper.instance.database;
    return db.query(
      DatabaseSchema.notificacoesTable,
      where: 'deleted_notificacao = ?',
      whereArgs: [0],
      orderBy: 'id_notificacao DESC',
    );
  }

  /// Marks a notification as read locally.
  Future<void> marcarComoLida(int idNotificacao) async {
    final db = await DatabaseHelper.instance.database;
    final agora = DateTime.now().toIso8601String();
    
    await db.update(
      DatabaseSchema.notificacoesTable,
      {
        'lida': 1,
        'last_read': agora,
      },
      where: 'id_notificacao = ?',
      whereArgs: [idNotificacao],
    );
    _changes.add(idNotificacao);
  }

  /// Batch upserts notifications (with built-in read states) from sync.
  Future<void> upsertFromSync(List<Map<String, dynamic>> dados) async {
    final db = await DatabaseHelper.instance.database;
    final batch = db.batch();

    for (final raw in dados) {
      // Validação dupla: tanto o ID da notificação como o ID do utilizador são obrigatórios
      final idNotificacao = intOrNull(raw['id_notificacao'] ?? raw['notificacao_id'] ?? raw['id']);
      final idUtilizador = intOrNull(raw['id_utilizador'] ?? raw['user_id']);

      if (idNotificacao == null || idUtilizador == null) {
        print('⚠️ [NotificacoesDao] Ignorado por idNotificacao ou id_utilizador nulo: $raw');
        continue;
      }

      batch.insert(
        DatabaseSchema.notificacoesTable,
        {
          'id_notificacao': idNotificacao,
          'id_utilizador': idUtilizador,
          // descricao_notificacao é NOT NULL — garante fallback seguro
          'descricao_notificacao': raw['descricao_notificacao']?.toString() ??
              raw['descricao']?.toString() ??
              raw['mensagem']?.toString() ??
              raw['titulo']?.toString() ??
              'Sem descrição',
          // tipo_notificacao é NOT NULL — garante fallback seguro
          'tipo_notificacao': raw['tipo_notificacao']?.toString() ??
              raw['tipo']?.toString() ??
              'Geral',
          // data_envio é nullable no schema
          'data_envio': raw['data_envio']?.toString() ??
              raw['criado_em']?.toString() ??
              raw['created_at']?.toString(),
          // lida é NOT NULL — converte boolean/int de forma segura
          'lida': (raw['lida'] == true || raw['lida'] == 1 || raw['lida'] == '1') ? 1 : 0,
          'last_read': raw['last_read']?.toString(),
          'notificacao_json': raw['notificacao_json']?.toString(),
          'updated_notificacao': raw['updated_notificacao']?.toString() ??
              raw['updated_at']?.toString(),
          'deleted_notificacao':
              (raw['deleted_notificacao'] == true || raw['deleted_notificacao'] == 1) ? 1 : 0,
        },
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
    }

    await batch.commit(noResult: true);
    _changes.add(-1);
  }

  /// Marca como eliminadas (soft delete) as notificações com os IDs fornecidos.
  /// Chamado pelo SyncManager quando o servidor envia um envelope { "deleted": [...] }.
  Future<void> deleteByIds(List<int> ids) async {
    if (ids.isEmpty) return;
    final db = await DatabaseHelper.instance.database;
    final batch = db.batch();
    for (final id in ids) {
      batch.update(
        DatabaseSchema.notificacoesTable,
        {'deleted_notificacao': 1},
        where: 'id_notificacao = ?',
        whereArgs: [id],
      );
    }
    await batch.commit(noResult: true);
    _changes.add(-1);
  }

  /// Atualiza o ID do servidor de uma notificação local (caso aplicável).
  Future<void> marcarComoSincronizado(int idLocal, int idServidor, [DatabaseExecutor? executor]) async {
    final db = executor ?? await DatabaseHelper.instance.database;
    await db.update(
      DatabaseSchema.notificacoesTable,
      {
        'id_notificacao': idServidor,
      },
      where: 'id_notificacao = ?',
      whereArgs: [idLocal],
    );
    print('✅ [SQLite Update] Notificação local $idLocal atualizada para ID Servidor $idServidor');
  }
}