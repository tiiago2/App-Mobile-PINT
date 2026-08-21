import 'dart:async';
import 'package:sqflite/sqflite.dart';
import '../database_helper.dart';
import '../database_schema.dart';
import '../sync_helpers.dart';

class PermissoesDao {
  PermissoesDao._();
  static final PermissoesDao instance = PermissoesDao._();

  final _changes = StreamController<int>.broadcast();
  Stream<int> get changes => _changes.stream;

  /// Retrieves a specific permission by user_id and key.
  Future<Map<String, dynamic>?> getPermissao(int userId, String permissionKey) async {
    final db = await DatabaseHelper.instance.database;
    final rows = await db.query(
      DatabaseSchema.permissoesTable,
      where: 'user_id = ? AND permission_key = ? AND (deleted_at = 0 OR deleted_at IS NULL)',
      whereArgs: [userId, permissionKey],
      limit: 1,
    );
    if (rows.isEmpty) return null;
    return rows.first;
  }

  /// Lists all active permissions for a user.
  Future<List<Map<String, dynamic>>> getPermissoesDoUtilizador(int userId) async {
    final db = await DatabaseHelper.instance.database;
    return db.query(
      DatabaseSchema.permissoesTable,
      where: 'user_id = ? AND (deleted_at = 0 OR deleted_at IS NULL)',
      whereArgs: [userId],
    );
  }

  /// Batch upserts permissions from sync.
  Future<void> upsertFromSync(List<Map<String, dynamic>> dados) async {
    final db = await DatabaseHelper.instance.database;
    final batch = db.batch();
    for (final raw in dados) {
      final idPermissao = intOrNull(raw['id_permissao'] ?? raw['id']);

      if (idPermissao == null) {
        print('⚠️ [PermissoesDao] Ignorado: id_permissao é nulo');
        continue;
      }

      final toggle = (raw['toggle'] == true || raw['toggle'] == 1) ? 1 : 0;
      final deletedPermissao = (raw['deleted_permissao'] == true || raw['deleted_permissao'] == 1) ? 1 : 0;

      batch.insert(
        DatabaseSchema.permissoesTable,
        {
          'id_permissao': idPermissao,
          'descricao_permissao': raw['descricao_permissao'] ?? raw['descricao'] ?? raw['permission_key'] ?? '',
          'toggle': toggle,
          'scope_json': raw['scope_json'],
          'updated_permissao': raw['updated_permissao']?.toString() ?? raw['updated_at']?.toString() ?? raw['server_updated_at']?.toString(),
          'deleted_permissao': deletedPermissao,
        },
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
    }
    await batch.commit(noResult: true);
    _changes.add(-1);
  }
}
