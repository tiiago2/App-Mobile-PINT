import 'dart:async';
import 'package:sqflite/sqflite.dart';
import '../database_helper.dart';
import '../database_schema.dart';
import '../sync_helpers.dart';

class ServiceLinesDao {
  ServiceLinesDao._internal();
  static final ServiceLinesDao instance = ServiceLinesDao._internal();

  final _changes = StreamController<int>.broadcast();
  Stream<int> get changes => _changes.stream;

  /// Retrieves a specific service line by ID.
  Future<Map<String, dynamic>?> getServiceLine(int serviceLineId) async {
    final db = await DatabaseHelper.instance.database;
    final rows = await db.query(
      DatabaseSchema.serviceLinesTable,
      where: 'id_service_line = ? AND deleted_service IS NULL',
      whereArgs: [serviceLineId],
      limit: 1,
    );
    if (rows.isEmpty) return null;
    return rows.first;
  }

  /// Lists all active service lines.
  Future<List<Map<String, dynamic>>> getServiceLines() async {
    final db = await DatabaseHelper.instance.database;
    return db.query(
      DatabaseSchema.serviceLinesTable,
      where: 'deleted_service IS NULL',
    );
  }

  /// Batch upserts service lines from sync.
  Future<void> upsertFromSync(List<Map<String, dynamic>> dados) async {
    final db = await DatabaseHelper.instance.database;
    final batch = db.batch();
    for (final raw in dados) {
      final valLine = raw['id_service_line'] ?? raw['service_line_id'] ?? raw['id'];
      final serviceLineId = valLine != null ? int.tryParse(valLine.toString()) : null;

      if (serviceLineId == null) {
        print('⚠️ [ServiceLinesDao] Ignorado por ID nulo: $raw');
        continue;
      }
      
      final deletedService = (raw['deleted_service'] == true || raw['deleted_service'] == 1 || raw['deleted_at'] != null) ? 1 : 0;

      batch.insert(
        DatabaseSchema.serviceLinesTable,
        {
          'id_service_line': serviceLineId,
          'nome_service_line': raw['nome_service_line'] ?? raw['nome'] ?? '',
          'id_learning_path': intOrNull(raw['id_learning_path'] ?? raw['learning_path_id']),
          'updated_service': raw['updated_service']?.toString() ?? raw['updated_at']?.toString() ?? raw['server_updated_at']?.toString(),
          'deleted_service': deletedService,
        },
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
    }
    await batch.commit(noResult: true);
    _changes.add(-1);
  }
}
