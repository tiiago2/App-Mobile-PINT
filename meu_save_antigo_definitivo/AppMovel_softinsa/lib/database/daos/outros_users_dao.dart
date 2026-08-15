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
  Future<void> upsertFromSync(List<dynamic> dados) async {
    final db = await DatabaseHelper.instance.database;
    final batch = db.batch();
    for (final item in dados) {
      if (item is! Map) continue;
      final idUtilizador = item['id_utilizador'];
      if (idUtilizador == null) {
        print('⚠️ [OutrosUsersDao] Ignorado: id_utilizador é nulo');
        continue;
      }

      batch.insert(
        DatabaseSchema.outrosUsersTable,
        {
          'id_utilizador': idUtilizador,
          'nome_user': item['nome_user'] ?? '',
          'id_area': item['id_area'],
          'imagem_perfil': item['imagem_perfil'],
          'update_user': item['update_user'] ?? DateTime.now().toIso8601String(),
          'pontos_semana': item['pontos_semana'] ?? 0,
          'pontos_mes': item['pontos_mes'] ?? 0,
          'pontos_ano': item['pontos_ano'] ?? 0,
          'pontos_totais': item['pontos_totais'] ?? 0,
          'ativo': item['ativo'] ?? 1,
        },
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
    }
    await batch.commit(noResult: true);
    _changes.add(-1);
  }
}
