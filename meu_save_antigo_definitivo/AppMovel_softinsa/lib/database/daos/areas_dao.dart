import 'dart:async';
import 'package:sqflite/sqflite.dart';
import '../database_helper.dart';
import '../database_schema.dart';
import '../sync_helpers.dart';

class AreasDao {
  AreasDao._();
  static final AreasDao instance = AreasDao._();

  final _changes = StreamController<int>.broadcast();
  Stream<int> get changes => _changes.stream;

  /// Retrieves a specific area by ID.
  Future<Map<String, dynamic>?> getArea(int areaId) async {
    final db = await DatabaseHelper.instance.database;
    final rows = await db.query(
      DatabaseSchema.areasTable,
      where: 'id_area = ? AND deleted_area IS NOT 1',
      whereArgs: [areaId],
      limit: 1,
    );
    if (rows.isEmpty) return null;
    return rows.first;
  }

  /// Lists all active areas.
  Future<List<Map<String, dynamic>>> getAreas() async {
    final db = await DatabaseHelper.instance.database;
    return db.query(
      DatabaseSchema.areasTable,
      where: 'deleted_area IS NOT 1',
    );
  }

  /// Batch upserts areas from sync.
  Future<void> upsertFromSync(List<Map<String, dynamic>> dados) async {
    final db = await DatabaseHelper.instance.database;
    final batch = db.batch();
    for (final raw in dados) {
      final areaId = intOrNull(raw['id_area'] ?? raw['area_id'] ?? raw['id']);
      if (areaId == null) {
        print('⚠️ [AreasDao] Ignorado: id_area é nulo');
        continue;
      }
      
      final deletedArea = (raw['deleted_area'] == true || raw['deleted_area'] == 1 || raw['deleted_at'] != null) ? 1 : 0;

      batch.insert(
        DatabaseSchema.areasTable,
        {
          'id_area': areaId,
          'id_service_line': intOrNull(raw['id_service_line'] ?? raw['service_line_id'] ?? (raw['service_line'] is Map ? (raw['service_line'] as Map)['id_service_line'] ?? (raw['service_line'] as Map)['id'] : null)),
          'nome_area': raw['nome_area'] ?? '',
          'updated_area': raw['updated_area']?.toString() ?? raw['updated_at']?.toString() ?? raw['server_updated_at']?.toString(),
          'deleted_area': deletedArea,
        },
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
    }
    await batch.commit(noResult: true);
    _changes.add(-1);
  }
}
