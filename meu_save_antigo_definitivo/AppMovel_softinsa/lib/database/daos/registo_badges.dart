import 'dart:async';
import 'dart:convert';
import 'package:sqflite/sqflite.dart';
import '../database_helper.dart';
import '../database_schema.dart';
import '../sync_helpers.dart';

class RegistoBadgesDao {
  RegistoBadgesDao._internal();
  static final RegistoBadgesDao instance = RegistoBadgesDao._internal();

  final _changes = StreamController<int>.broadcast();
  Stream<int> get changes => _changes.stream;

  /// Retrieves a specific badge record by ID.
  Future<Map<String, dynamic>?> getRegistoBadge(int userId, int registoId) async {
    final db = await DatabaseHelper.instance.database;
    final rows = await db.query(
      DatabaseSchema.registoBadgesTable,
      where: 'id_utilizador = ? AND id_registo = ? AND deleted_registo IS NULL',
      whereArgs: [userId, registoId],
      limit: 1,
    );
    if (rows.isEmpty) return null;
    return rows.first;
  }

  /// Lists all badge records for a user.
  Future<List<Map<String, dynamic>>> getRegistosDoUtilizador(int userId) async {
    final db = await DatabaseHelper.instance.database;
    return db.rawQuery(
      '''
      SELECT r.*, b.badge_json, b.nome_badge, b.imagem, b.validade
      FROM ${DatabaseSchema.registoBadgesTable} r
      JOIN ${DatabaseSchema.badgesTable} b ON b.id_badge = r.id_badge
      WHERE r.id_utilizador = ? AND r.deleted_registo IS NULL
      ORDER BY r.data_obtencao DESC
    ''',
      [userId],
    );
  }

  /// Batch upserts badge records from sync.
  Future<void> upsertFromSync(List<Map<String, dynamic>> dados) async {
    final db = await DatabaseHelper.instance.database;
    final batch = db.batch();
    for (final raw in dados) {
      final id = intOrNull(raw['id_registo'] ?? raw['registo_id'] ?? raw['id']);
      final userId = intOrNull(raw['id_utilizador'] ?? raw['user_id']);
      final badgeId = intOrNull(raw['id_badge'] ?? raw['badge_id']);
      final data = raw['data_obtencao']?.toString();
      if (id == null || userId == null || badgeId == null || data == null) {
        print('⚠️ [RegistoBadgesDao] Ignorado por ID nulo: $raw');
        continue;
      }

      final expirado = (raw['expirado'] == true || raw['expirado'] == 1 || raw['expirado'] == '1') ? 1 : 0;
      final deletedRegisto = (raw['deleted_registo'] == true || raw['deleted_registo'] == 1 || raw['deleted_registo'] == '1' || raw['deleted_at'] != null) ? 1 : 0;

      batch.insert(
        DatabaseSchema.registoBadgesTable,
        {
          'id_utilizador': userId,
          'id_registo': id,
          'id_badge': badgeId,
          'data_obtencao': data,
          'expirado': expirado,
          'registo_json': raw['registo_json'] ?? jsonEncode(raw),
          'updated_registo': raw['updated_registo']?.toString() ?? raw['updated_at']?.toString() ?? raw['server_updated_at']?.toString(),
          'deleted_registo': deletedRegisto,
        },
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
    }
    await batch.commit(noResult: true);
    _changes.add(-1);
  }

  // Backward compatibility methods
  Future<List<Map<String, dynamic>>> lerRegistosDoUtilizador(int userId) async {
    return getRegistosDoUtilizador(userId);
  }

  Future<void> substituirRegistosDoUtilizador({
    required int userId,
    required List<Map<String, dynamic>> registos,
  }) async {
    await upsertFromSync(registos.map((r) => {...r, 'id_utilizador': userId}).toList());
  }

  /// Atualiza o ID do servidor de um registo de badge local (caso aplicável).
  Future<void> marcarComoSincronizado(int idLocal, int idServidor, [DatabaseExecutor? executor]) async {
    final db = executor ?? await DatabaseHelper.instance.database;
    await db.update(
      DatabaseSchema.registoBadgesTable,
      {
        'id_registo': idServidor,
      },
      where: 'id_registo = ?',
      whereArgs: [idLocal],
    );
    print('✅ [SQLite Update] Registo de badge local $idLocal atualizada para ID Servidor $idServidor');
  }
}

typedef RegistoBadgeDao = RegistoBadgesDao;
