import 'dart:async';
import 'dart:convert';
import 'package:sqflite/sqflite.dart';
import '../database_helper.dart';
import '../database_schema.dart';
import '../sync_helpers.dart';

class BadgesDao {
  BadgesDao._();
  static final BadgesDao instance = BadgesDao._();

  final _changes = StreamController<int>.broadcast();
  Stream<int> get changes => _changes.stream;

  /// Retrieves a specific badge by ID.
  Future<Map<String, dynamic>?> getBadge(int badgeId) async {
    final db = await DatabaseHelper.instance.database;
    final rows = await db.query(
      DatabaseSchema.badgesTable,
      where: 'id_badge = ? AND (deleted_badge = 0 OR deleted_badge IS NULL)',
      whereArgs: [badgeId],
      limit: 1,
    );
    if (rows.isEmpty) return null;
    return rows.first;
  }

  /// Lists all active badges.
  Future<List<Map<String, dynamic>>> getBadges() async {
    final db = await DatabaseHelper.instance.database;
    return db.query(
      DatabaseSchema.badgesTable,
      where: 'deleted_badge = 0 OR deleted_badge IS NULL',
    );
  }

  /// Batch upserts badges from sync.
  Future<void> upsertFromSync(List<Map<String, dynamic>> dados) async {
    final db = await DatabaseHelper.instance.database;
    final batch = db.batch();
    for (final raw in dados) {
      final idBadge = intOrNull(raw['id_badge'] ?? raw['badge_id'] ?? raw['id']);
      if (idBadge == null) {
        print('⚠️ [BadgesDao] Ignorado: id_badge é nulo');
        continue;
      }
      
      final especial = (raw['especial'] == true || raw['especial'] == 1) ? 1 : 0;
      final deletedBadge = (raw['deleted_badge'] == true || raw['deleted_badge'] == 1) ? 1 : 0;

      final cleanRow = {
        'id_badge': idBadge,
        'nome_badge': raw['nome_badge'] ?? raw['titulo'] ?? '',
        'descricao_badge': raw['descricao_badge'] ?? raw['descricao'],
        'imagem': raw['imagem'],
        'especial': especial,
        'pontos_badge': intOrNull(raw['pontos_badge'] ?? raw['pontos']),
        'validade': intOrNull(raw['validade']),
        'id_area': intOrNull(raw['id_area'] ?? raw['area_id']),
        'id_nivel': intOrNull(raw['id_nivel'] ?? raw['nivel_id']),
        'badge_json': raw['badge_json'] ?? jsonEncode(raw),
        'update_badge': raw['update_badge']?.toString() ?? raw['server_updated_at']?.toString() ?? raw['updated_at']?.toString(),
        'deleted_badge': deletedBadge,
        'cached_at': utcNow(),
      };

      batch.insert(
        DatabaseSchema.badgesTable,
        cleanRow,
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
    }
    await batch.commit(noResult: true);
    _changes.add(-1);
  }

  /// Compatibility snapshot method for sync_service.dart
  Future<void> aplicarSnapshotRemoto({
    required int userId,
    required List<Map<String, dynamic>> badges,
    bool snapshotCompleto = true,
  }) async {
    final db = await DatabaseHelper.instance.database;
    await db.transaction((txn) async {
      final incomingIds = <int>[];
      for (final raw in badges) {
        final nestedBadge = raw['badge'];
        final global = nestedBadge is Map
            ? {...Map<String, dynamic>.from(nestedBadge), ...raw}
            : raw;
        final badgeId = intOrNull(global['id_badge'] ?? global['badge_id']);
        if (badgeId == null) continue;
        incomingIds.add(badgeId);
        final area = global['area'] is Map ? global['area'] as Map : null;
        final nivel = global['nivel'] is Map ? global['nivel'] as Map : null;
        final existingBadge = await txn.query(
          DatabaseSchema.badgesTable,
          where: 'id_badge = ?',
          whereArgs: [badgeId],
          limit: 1,
        );
        final previousBadge = existingBadge.isEmpty
            ? const <String, Object?>{}
            : existingBadge.first;

        final deletedBadge = (global['deleted_badge'] == true || global['deleted_badge'] == 1 || global['deleted_at'] != null) ? 1 : 0;

        final badgeValues = <String, Object?>{
          'id_badge': badgeId,
          'nome_badge':
              global['nome_badge'] ??
              global['titulo'] ??
              previousBadge['nome_badge'] ??
              '',
          'descricao_badge':
              global['descricao_badge'] ??
              global['descricao'] ??
              previousBadge['descricao_badge'],
          'imagem': global['imagem'] ?? previousBadge['imagem'],
          'especial': global.containsKey('especial')
              ? global['especial'] == true || global['especial'] == 1
                    ? 1
                    : 0
              : previousBadge['especial'] ?? 0,
          'pontos_badge':
              intOrNull(global['pontos_badge'] ?? global['pontos']) ??
              previousBadge['pontos_badge'],
          'validade':
              intOrNull(global['validade']) ?? previousBadge['validade'],
          'id_area':
              intOrNull(
                area?['id_area'] ?? global['area_id'] ?? global['id_area'],
              ) ??
              previousBadge['id_area'],
          'id_nivel':
              intOrNull(
                nivel?['id_nivel'] ?? global['nivel_id'] ?? global['id_nivel'],
              ) ??
              previousBadge['id_nivel'],
          'badge_json': jsonEncode(raw),
          'update_badge': global['update_badge'] ?? global['updated_at'],
          'deleted_badge': deletedBadge,
          'cached_at': utcNow(),
        };
        if (existingBadge.isEmpty) {
          await txn.insert(DatabaseSchema.badgesTable, badgeValues);
        } else if (remoteVersionIsCurrent(
          global['updated_at'] ?? global['update_badge'],
          previousBadge['update_badge'],
        )) {
          await txn.update(
            DatabaseSchema.badgesTable,
            badgeValues,
            where: 'id_badge = ?',
            whereArgs: [badgeId],
          );
        }
      }
    });
    _changes.add(userId);
  }

  Future<List<Map<String, dynamic>>> lerBadgesDoUtilizador(int userId) async {
    // Note: user_badges_cache table was removed. We fetch all active badges.
    return getBadges();
  }

  Future<List<Map<String, dynamic>>> lerRequisitosDoBadge(int badgeId) async {
    final db = await DatabaseHelper.instance.database;
    return db.rawQuery(
      '''
      SELECT r.* FROM ${DatabaseSchema.requisitosTable} r
      JOIN ${DatabaseSchema.badgesRequisitosTable} br ON br.id_requisito = r.id_requisito
      WHERE br.id_badge = ? AND (r.deleted_requisito = 0 OR r.deleted_requisito IS NULL)
    ''',
      [badgeId],
    );
  }
}

typedef BadgeDao = BadgesDao;
