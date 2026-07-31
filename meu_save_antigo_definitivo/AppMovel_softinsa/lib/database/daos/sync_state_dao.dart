import 'package:sqflite/sqflite.dart';
import '../database_helper.dart';
import '../database_schema.dart';

class SyncStateDao {
  /// Obtém o cursor de sincronização para um utilizador e entidade.
  Future<String?> getCursor(int userId, String entity) async {
    final db = await DatabaseHelper.instance.database;
    final rows = await db.query(
      DatabaseSchema.syncStateTable,
      columns: ['cursor'],
      where: 'user_id = ? AND entity = ?',
      whereArgs: [userId, entity],
      limit: 1,
    );
    if (rows.isEmpty) return null;
    return rows.first['cursor'] as String?;
  }

  /// Atualiza o cursor de sincronização para um utilizador e entidade.
  Future<void> updateCursor(int userId, String entity, String cursor) async {
    final db = await DatabaseHelper.instance.database;
    final now = DateTime.now().toUtc().toIso8601String();
    await db.insert(
      DatabaseSchema.syncStateTable,
      {
        'user_id': userId,
        'entity': entity,
        'cursor': cursor,
        'last_sync_at': now,
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }
}
