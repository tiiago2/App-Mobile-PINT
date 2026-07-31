import 'dart:async';
import 'package:sqflite/sqflite.dart';
import '../database_helper.dart';
import '../database_schema.dart';

import '../sync_helpers.dart';

class BadgesRequisitosDao {
  BadgesRequisitosDao._();
  static final BadgesRequisitosDao instance = BadgesRequisitosDao._();

  final _changes = StreamController<int>.broadcast();
  Stream<int> get changes => _changes.stream;

  /// Retrieves list of requirements for a badge.
  Future<List<Map<String, dynamic>>> getRequisitosDoBadge(int badgeId) async {
    final db = await DatabaseHelper.instance.database;
    return db.query(
      DatabaseSchema.badgesRequisitosTable,
      where: 'id_badge = ?',
      whereArgs: [badgeId],
    );
  }

  /// Batch upserts badge requirements relations from sync.
  Future<void> upsertFromSync(List<Map<String, dynamic>> dados) async {
    final db = await DatabaseHelper.instance.database;
    final batch = db.batch();
    for (final raw in dados) {
      final idRequisito = intOrNull(raw['id_requisito'] ?? raw['requisito_id'] ?? raw['id']);
      final idBadge = intOrNull(raw['id_badge'] ?? raw['badge_id']);

      if (idRequisito == null || idBadge == null) {
        print('⚠️ [BadgesRequisitosDao] Chaves nulas! O objeto completo recebido foi: $raw');
        continue;
      }

      batch.insert(
        DatabaseSchema.badgesRequisitosTable,
        {
          'id_requisito': idRequisito,
          'id_badge': idBadge,
        },
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
    }
    await batch.commit(noResult: true);
    _changes.add(-1);
  }
}
