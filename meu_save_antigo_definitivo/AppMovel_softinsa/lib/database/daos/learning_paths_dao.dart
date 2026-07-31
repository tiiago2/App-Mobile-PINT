import 'dart:async';
import 'package:sqflite/sqflite.dart';
import '../database_helper.dart';
import '../database_schema.dart';
import '../sync_helpers.dart';

class LearningPathsDao {
  LearningPathsDao._internal();
  static final LearningPathsDao instance = LearningPathsDao._internal();

  final _changes = StreamController<int>.broadcast();
  Stream<int> get changes => _changes.stream;

  /// Retrieves a specific learning path by ID.
  Future<Map<String, dynamic>?> getLearningPath(int learningPathId) async {
    final db = await DatabaseHelper.instance.database;
    final rows = await db.query(
      DatabaseSchema.learningPathsTable,
      where: 'id_learning_path = ? AND deleted_path IS NULL',
      whereArgs: [learningPathId],
      limit: 1,
    );
    if (rows.isEmpty) return null;
    return rows.first;
  }

  /// Lists all active learning paths.
  Future<List<Map<String, dynamic>>> getLearningPaths() async {
    final db = await DatabaseHelper.instance.database;
    return db.query(
      DatabaseSchema.learningPathsTable,
      where: 'deleted_path IS NULL',
    );
  }

  /// Batch upserts learning paths from sync.
  Future<void> upsertFromSync(List<Map<String, dynamic>> dados) async {
    final db = await DatabaseHelper.instance.database;
    final batch = db.batch();
    for (final raw in dados) {
      final valPath = raw['id_learning_path'] ?? raw['learning_path_id'] ?? raw['id'];
      final learningPathId = valPath != null ? int.tryParse(valPath.toString()) : null;

      if (learningPathId == null) {
        print('⚠️ [LearningPathsDao] Ignorado por ID nulo: $raw');
        continue;
      }
      
      final deletedPath = (raw['deleted_path'] == true || raw['deleted_path'] == 1 || raw['deleted_at'] != null) ? 1 : 0;

      batch.insert(
        DatabaseSchema.learningPathsTable,
        {
          'id_learning_path': learningPathId,
          'nome_learning_path': raw['nome_learning_path'] ?? raw['nome'] ?? '',
          'descricao_larning_path': raw['descricao_larning_path'] ?? raw['descricao'] ?? raw['descricao_learning_path'],
          'updated_path': raw['updated_path']?.toString() ?? raw['updated_at']?.toString() ?? raw['server_updated_at']?.toString(),
          'deleted_path': deletedPath,
        },
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
    }
    await batch.commit(noResult: true);
    _changes.add(-1);
  }
}
