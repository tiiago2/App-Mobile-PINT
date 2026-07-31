import 'dart:async';
import 'package:sqflite/sqflite.dart';
import '../database_helper.dart';
import '../database_schema.dart';
import '../sync_helpers.dart';

class BadgesAssinaturaDao {
  BadgesAssinaturaDao._();
  static final BadgesAssinaturaDao instance = BadgesAssinaturaDao._();

  final _changes = StreamController<int>.broadcast();
  Stream<int> get changes => _changes.stream;

  /// Retrieves the badges linked to an active signature.
  Future<List<Map<String, dynamic>>> getBadgesDaAssinatura(int assinaturaLocalId) async {
    final db = await DatabaseHelper.instance.database;
    return db.query(
      DatabaseSchema.badgesAssinaturaTable,
      where: 'id_assinatura_local = ?',
      whereArgs: [assinaturaLocalId],
    );
  }

  /// Inserts a new badge to the signature.
  /// Critical business rule: max 4 badges allowed.
  Future<void> insertBadgeAssinatura(int assinaturaLocalId, int badgeId) async {
    final db = await DatabaseHelper.instance.database;
    
    await db.transaction((txn) async {
      final rows = await txn.rawQuery(
        'SELECT COUNT(*) FROM ${DatabaseSchema.badgesAssinaturaTable} WHERE id_assinatura_local = ?',
        [assinaturaLocalId],
      );
      final count = Sqflite.firstIntValue(rows) ?? 0;
      if (count >= 4) {
        throw Exception('Máximo de 4 badges atingido');
      }

      await txn.insert(
        DatabaseSchema.badgesAssinaturaTable,
        {
          'id_assinatura_local': assinaturaLocalId,
          'id_badge': badgeId,
        },
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
    });

    _changes.add(assinaturaLocalId);
  }

  /// Replaces an old badge with a new one for a given signature.
  Future<void> updateBadgeAssinatura(int assinaturaLocalId, int oldBadgeId, int newBadgeId) async {
    final db = await DatabaseHelper.instance.database;
    
    await db.update(
      DatabaseSchema.badgesAssinaturaTable,
      {'id_badge': newBadgeId},
      where: 'id_assinatura_local = ? AND id_badge = ?',
      whereArgs: [assinaturaLocalId, oldBadgeId],
    );

    _changes.add(assinaturaLocalId);
  }

  /// Batch upserts signature badge connections.
  Future<void> upsertFromSync(List<Map<String, dynamic>> dados) async {
    final db = await DatabaseHelper.instance.database;
    
    final batch = db.batch();
    for (final raw in dados) {
      final idBadge = intOrNull(raw['id_badge'] ?? raw['badge_id'] ?? raw['id']);
      final serverIdAssinatura = intOrNull(raw['id_assinatura'] ?? raw['assinatura_id'] ?? raw['id']);

      if (serverIdAssinatura == null || idBadge == null) {
        print('⚠️ [BadgesAssinaturaDao] Ignorado por id_assinatura ou id_badge nulo: $raw');
        continue;
      }

      // 1. Procurar o ID local da assinatura na tabela local 'assinaturas'
      final List<Map<String, dynamic>> res = await db.query(
        DatabaseSchema.assinaturaTable,
        columns: ['id_assinatura_local'],
        where: 'id_assinatura = ? OR id_assinatura_local = ?',
        whereArgs: [serverIdAssinatura, serverIdAssinatura],
        limit: 1,
      );

      if (res.isEmpty) {
        print('⚠️ [BadgesAssinaturaDao] Ignorado: Assinatura pai (ID $serverIdAssinatura) não encontrada no SQLite local.');
        continue;
      }

      final idAssinaturaLocal = res.first['id_assinatura_local'] as int;

      batch.insert(
        DatabaseSchema.badgesAssinaturaTable,
        {
          'id_assinatura_local': idAssinaturaLocal,
          'id_badge': idBadge,
        },
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
    }
    await batch.commit(noResult: true);
    _changes.add(-1);
  }
}
