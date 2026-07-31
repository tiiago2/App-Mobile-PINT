import 'dart:async';
import 'package:sqflite/sqflite.dart';
import '../database_helper.dart';
import '../database_schema.dart';
import '../sync_helpers.dart';

class NiveisDao {
  NiveisDao._();
  static final NiveisDao instance = NiveisDao._();

  final _changes = StreamController<int>.broadcast();
  Stream<int> get changes => _changes.stream;

  /// Retrieves a specific level by ID.
  Future<Map<String, dynamic>?> getNivel(int nivelId) async {
    final db = await DatabaseHelper.instance.database;
    final rows = await db.query(
      DatabaseSchema.niveisTable,
      where: 'id_nivel = ? AND deleted_nivel IS NULL',
      whereArgs: [nivelId],
      limit: 1,
    );
    if (rows.isEmpty) return null;
    return rows.first;
  }

  /// Lists all active levels.
  Future<List<Map<String, dynamic>>> getNiveis() async {
    final db = await DatabaseHelper.instance.database;
    return db.query(
      DatabaseSchema.niveisTable,
      where: 'deleted_nivel IS NULL',
    );
  }

  /// Batch upserts levels from sync.
  Future<void> upsertFromSync(List<Map<String, dynamic>> dados) async {
    final db = await DatabaseHelper.instance.database;
    final batch = db.batch();
    for (final raw in dados) {
      final nivelId = intOrNull(raw['id_nivel'] ?? raw['nivel_id'] ?? raw['id']);
      if (nivelId == null) {
        print('⚠️ [NiveisDao] Ignorado: id_nivel é nulo');
        continue;
      }
      
      final deletedNivel = (raw['deleted_nivel'] == true || raw['deleted_nivel'] == 1 || raw['deleted_at'] != null) ? 1 : 0;

      batch.insert(
        DatabaseSchema.niveisTable,
        {
          'id_nivel': nivelId,
          'nome_nivel': raw['nome_nivel'] ?? raw['nome'] ?? '',
          'updated_nivel': raw['updated_nivel']?.toString() ?? raw['updated_at']?.toString() ?? raw['server_updated_at']?.toString(),
          'deleted_nivel': deletedNivel,
        },
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
    }
    await batch.commit(noResult: true);
    _changes.add(-1);
  }
}
