import 'dart:async';
import 'package:sqflite/sqflite.dart';
import '../database_helper.dart';
import '../database_schema.dart';
import '../sync_helpers.dart';

class OutrosUsersDao {
  OutrosUsersDao._();
  static final OutrosUsersDao instance = OutrosUsersDao._();

  final _changes = StreamController<int>.broadcast();
  Stream<int> get changes => _changes.stream;

  /// Retrieves a specific other user by ID.
  Future<Map<String, dynamic>?> getUser(int userId) async {
    final db = await DatabaseHelper.instance.database;
    final rows = await db.query(
      DatabaseSchema.outrosUsersTable,
      where: 'id_utilizador = ? AND ativo = 1',
      whereArgs: [userId],
      limit: 1,
    );
    if (rows.isEmpty) return null;
    return rows.first;
  }

  /// Lists all active other users cached locally.
  Future<List<Map<String, dynamic>>> getUsers() async {
    final db = await DatabaseHelper.instance.database;
    return db.query(
      DatabaseSchema.outrosUsersTable,
      where: 'ativo = 1',
    );
  }

  /// Batch upserts other users from sync.
  Future<void> upsertFromSync(List<Map<String, dynamic>> dados) async {
    final db = await DatabaseHelper.instance.database;
    final batch = db.batch();
    for (final raw in dados) {
      final idUtilizador = intOrNull(raw['id_utilizador'] ?? raw['user_id'] ?? raw['id']);
      if (idUtilizador == null) {
        print('⚠️ [OutrosUsersDao] Ignorado: id_utilizador é nulo');
        continue;
      }

      final ativo = (raw['ativo'] == true || raw['ativo'] == 1 || raw['ativo'] == null) ? 1 : 0;
      
      batch.insert(
        DatabaseSchema.outrosUsersTable,
        {
          'id_utilizador': idUtilizador,
          'nome_user': raw['nome_user'] ?? raw['nome'] ?? '',
          'id_area': intOrNull(raw['id_area'] ?? raw['area_id']),
          'imagem_perfil': raw['imagem_perfil'] ?? raw['foto'] ?? raw['foto_perfil'],
          'update_user': raw['update_user']?.toString() ?? raw['updated_at']?.toString() ?? raw['server_updated_at']?.toString() ?? raw['update_user']?.toString(),
          'ativo': ativo,
        },
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
    }
    await batch.commit(noResult: true);
    _changes.add(-1);
  }
}
