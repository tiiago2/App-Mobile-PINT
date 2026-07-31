import 'dart:async';
import 'dart:convert';
import 'package:sqflite/sqflite.dart';
import '../database_helper.dart';
import '../database_schema.dart';
import '../sync_helpers.dart';
import 'sync_outbox_dao.dart';

class PerfilDao {
  PerfilDao._();
  static final PerfilDao instance = PerfilDao._();

  final _changes = StreamController<int>.broadcast();
  Stream<int> get changes => _changes.stream;

  /// Retrieves the profile cached local data for a user.
  Future<Map<String, dynamic>?> getPerfil(int userId) async {
    return lerPerfilDoUtilizador(userId);
  }

  /// App only update action. Insert is not allowed.
  Future<void> updatePerfilLocal(int userId, Map<String, dynamic> perfil) async {
    await guardarPerfilLocal(userId: userId, perfil: perfil);
  }

  /// Upserts sync data from the server.
  Future<void> upsertFromSync(List<Map<String, dynamic>> dados) async {
    final db = await DatabaseHelper.instance.database;
    final batch = db.batch();
    for (final raw in dados) {
      final userId = intOrNull(raw['user_id'] ?? raw['id']);
      if (userId == null) continue;
      final values = _normalizar(userId, raw, syncStatus: 'synced');
      batch.insert(
        DatabaseSchema.perfilTable,
        values,
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
    }
    await batch.commit(noResult: true);
    _changes.add(-1);
  }

  // --- Legacy Compatibility Methods ---

  Future<Map<String, dynamic>?> lerPerfilDoUtilizador(int userId) async {
    final db = await DatabaseHelper.instance.database;
    final rows = await db.query(
      DatabaseSchema.perfilTable,
      where: 'id_utilizador = ?',
      whereArgs: [userId],
      limit: 1,
    );
    if (rows.isEmpty) return null;
    final row = rows.first;
    Map<String, dynamic> profile = {};
    try {
      final decoded = jsonDecode(row['profile_json']?.toString() ?? '{}');
      if (decoded is Map) profile = Map<String, dynamic>.from(decoded);
    } on FormatException {
      profile = {};
    }
    return {
      ...profile,
      'id': userId,
      'user_id': userId,
      'nome': row['nome_user'],
      'email': row['email'],
      'telefone': row['telefone'],
      'foto': row['imagem_perfil'] ?? profile['foto'],
      'area': row['id_area'] ?? profile['area'],
      'last_login': row['last_login'],
      'local_updated_at': row['local_updated_at'],
      'server_updated_at': row['server_updated_at'],
      'sync_status': row['sync_status'],
    };
  }

  Future<void> guardarPerfilLocal({
    required int userId,
    required Map<String, dynamic> perfil,
  }) async {
    final db = await DatabaseHelper.instance.database;
    final existing = await db.query(
      DatabaseSchema.perfilTable,
      where: 'id_utilizador = ?',
      whereArgs: [userId],
      limit: 1,
    );
    if (existing.isEmpty) {
      throw Exception('Perfil não existe localmente. Operação de inserção não é permitida.');
    }
    final values = _normalizar(userId, perfil, syncStatus: 'pending_update');
    await db.transaction((txn) async {
      await txn.insert(
        DatabaseSchema.perfilTable,
        values,
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
      await txn.delete(
        DatabaseSchema.syncOutboxTable,
        where: "user_id = ? AND entity = 'perfil' AND local_record_id = ?",
        whereArgs: [userId, userId],
      );
      await SyncOutboxDao.instance.adicionarOperacaoNoExecutor(
        txn,
        userId: userId,
        entity: 'perfil',
        operation: 'update',
        localRecordId: userId,
        clientId: generateClientId(),
        payload: perfil,
      );
    });
    _changes.add(userId);
  }

  Future<void> aplicarPerfilRemoto({
    required int userId,
    required Map<String, dynamic> perfil,
  }) async {
    final db = await DatabaseHelper.instance.database;
    final existing = await db.query(
      DatabaseSchema.perfilTable,
      where: 'id_utilizador = ?',
      whereArgs: [userId],
      limit: 1,
    );
    if (existing.isNotEmpty && existing.first['sync_status'] != 'synced') {
      await db.update(
        DatabaseSchema.perfilTable,
        {'server_updated_at': perfil['updated_at']?.toString()},
        where: 'id_utilizador = ?',
        whereArgs: [userId],
      );
    } else if (existing.isEmpty ||
        remoteVersionIsCurrent(
          perfil['updated_at'],
          existing.first['server_updated_at'],
        )) {
      await db.insert(
        DatabaseSchema.perfilTable,
        _normalizar(userId, perfil, syncStatus: 'synced'),
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
    }
    _changes.add(userId);
  }

  Map<String, dynamic> _normalizar(
    int userId,
    Map<String, dynamic> perfil, {
    required String syncStatus,
  }) {
    final nome = perfil['nome']?.toString().trim();
    final email = perfil['email']?.toString().trim();
    if (userId <= 0 ||
        nome == null ||
        nome.isEmpty ||
        email == null ||
        email.isEmpty) {
      throw Exception('invalid_profile');
    }
    final valArea = perfil['id_area'] ?? perfil['area_id'] ?? (perfil['area'] is Map ? perfil['area']['id_area'] : null);
    final idArea = valArea?.toString();

    return {
      'id_utilizador': userId,
      'nome_user': nome,
      'email': email,
      'telefone': perfil['telefone']?.toString(),
      'imagem_perfil': (perfil['foto'] ?? perfil['foto_perfil'] ?? perfil['imagem_perfil'])?.toString(),
      'id_area': idArea,
      'last_login': perfil['last_login']?.toString(),
      'profile_json': jsonEncode({...perfil, 'id_utilizador': userId}),
      'local_updated_at': utcNow(),
      'server_updated_at': perfil['updated_at']?.toString() ?? perfil['server_updated_at']?.toString(),
      'sync_status': syncStatus,
    };
  }

  /// Atualiza o ID do servidor e o sync_status de um perfil local.
  Future<void> marcarComoSincronizado(int idLocal, int idServidor, [DatabaseExecutor? executor]) async {
    final db = executor ?? await DatabaseHelper.instance.database;
    await db.update(
      DatabaseSchema.perfilTable,
      {
        'id_utilizador': idServidor,
        'sync_status': 'synced',
      },
      where: 'id_utilizador = ?',
      whereArgs: [idLocal],
    );
    print('✅ [SQLite Update] Perfil local $idLocal atualizado para ID Servidor $idServidor (sync_status = synced)');
  }
}
