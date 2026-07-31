import 'dart:async';
import 'dart:convert';
import 'package:sqflite/sqflite.dart';
import '../database_helper.dart';
import '../database_schema.dart';
import '../sync_helpers.dart';

class RequisitosDao {
  RequisitosDao._();
  static final RequisitosDao instance = RequisitosDao._();

  final _changes = StreamController<int>.broadcast();
  Stream<int> get changes => _changes.stream;

  /// Retrieves a specific requirement by ID.
  Future<Map<String, dynamic>?> getRequisito(int requisitoId) async {
    final db = await DatabaseHelper.instance.database;
    final rows = await db.query(
      DatabaseSchema.requisitosTable,
      where: 'id_requisito = ? AND deleted_requisito IS NULL',
      whereArgs: [requisitoId],
      limit: 1,
    );
    if (rows.isEmpty) return null;
    return rows.first;
  }

  /// Lists all requirements.
  Future<List<Map<String, dynamic>>> getRequisitos() async {
    final db = await DatabaseHelper.instance.database;
    return db.query(
      DatabaseSchema.requisitosTable,
      where: 'deleted_requisito IS NULL',
    );
  }

  /// Batch upserts requirements from sync.
  Future<void> upsertFromSync(List<Map<String, dynamic>> dados) async {
    final db = await DatabaseHelper.instance.database;
    final batch = db.batch();
    for (final raw in dados) {
      final requisitoId = intOrNull(raw['id_requisito'] ?? raw['requisito_id'] ?? raw['id']);
      if (requisitoId == null) {
        print('⚠️ [RequisitosDao] Ignorado: id_requisito é nulo');
        continue;
      }
      final cleanRow = {
        'id_requisito': requisitoId,
        'nome_requisito': raw['nome_requisito'] ?? '',
        'descricao_requisito': raw['descricao_requisito'] ?? '',
        'requisito_json': raw['requisito_json'] ?? jsonEncode(raw),
        'update_requisito': raw['update_requisito']?.toString() ?? raw['update_requisitos']?.toString() ?? raw['updated_at']?.toString(),
        'deleted_requisito': raw['deleted_requisito']?.toString() ?? raw['deleted_at']?.toString(),
      };

      batch.insert(
        DatabaseSchema.requisitosTable,
        cleanRow,
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
    }
    await batch.commit(noResult: true);
    _changes.add(-1);
  }
}
