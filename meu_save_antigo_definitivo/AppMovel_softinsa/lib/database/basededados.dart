import 'dart:convert';

import 'package:path/path.dart' as p;
import 'package:sqflite/sqflite.dart';

class BaseDadosException implements Exception {
  final String message;

  const BaseDadosException(this.message);

  @override
  String toString() => message;
}

class Basededados {
  Basededados._();

  static final Basededados instance = Basededados._();

  static const String _databaseName = 'softinsa_mobile.db';
  static const int _databaseVersion = 2;
  static const String _perfilTable = 'perfil_cache';
  static const String _badgesTable = 'badges_cache';

  Database? _database;
  Future<Database>? _openingDatabase;

  Future<Database> get _db async {
    final database = _database;

    if (database != null && database.isOpen) {
      return database;
    }

    final openingDatabase = _openingDatabase;
    if (openingDatabase != null) {
      return openingDatabase;
    }

    _openingDatabase = _open();

    try {
      _database = await _openingDatabase;
      return _database!;
    } catch (_) {
      _openingDatabase = null;
      throw const BaseDadosException('open_failed');
    }
  }

  Future<Database> _open() async {
    final databasePath = await getDatabasesPath();
    final path = p.join(databasePath, _databaseName);

    return openDatabase(
      path,
      version: _databaseVersion,
      onCreate: _onCreate,
      onUpgrade: _onUpgrade,
    );
  }

  Future<void> _onCreate(Database db, int version) async {
    await db.execute('''
      CREATE TABLE $_perfilTable (
        cache_id INTEGER PRIMARY KEY,
        user_id INTEGER,
        email TEXT,
        profile_json TEXT NOT NULL,
        updated_at TEXT NOT NULL
      )
    ''');
    await _createBadgesTable(db);
  }

  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 2) {
      await _createBadgesTable(db);
    }
  }

  Future<void> _createBadgesTable(Database db) async {
    await db.execute('''
      CREATE TABLE IF NOT EXISTS $_badgesTable (
        badge_id INTEGER PRIMARY KEY,
        titulo TEXT NOT NULL,
        descricao TEXT,
        imagem TEXT,
        especial INTEGER NOT NULL DEFAULT 0,
        pontos INTEGER,
        validade INTEGER,
        area_id INTEGER,
        area_nome TEXT,
        nivel_id INTEGER,
        nivel_nome TEXT,
        minha_area INTEGER NOT NULL DEFAULT 0,
        estado TEXT NOT NULL,
        progresso INTEGER NOT NULL DEFAULT 0,
        update_badge TEXT,
        badge_json TEXT NOT NULL,
        cached_at TEXT NOT NULL
      )
    ''');
  }

  Future<void> guardarPerfil(Map<String, dynamic> perfil) async {
    if (perfil.isEmpty) {
      throw const BaseDadosException('invalid_profile');
    }

    try {
      final profileJson = jsonEncode(perfil);
      final userId = perfil['id'];
      final email = perfil['email'];
      final db = await _db;

      await db.insert(
        _perfilTable,
        {
          'cache_id': 1,
          'user_id': userId is int ? userId : null,
          'email': email is String ? email : null,
          'profile_json': profileJson,
          'updated_at': DateTime.now().toUtc().toIso8601String(),
        },
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
    } catch (_) {
      throw const BaseDadosException('save_profile_failed');
    }
  }

  Future<Map<String, dynamic>?> lerPerfil() async {
    try {
      final db = await _db;
      final rows = await db.query(
        _perfilTable,
        where: 'cache_id = ?',
        whereArgs: const [1],
        limit: 1,
      );

      if (rows.isEmpty) {
        return null;
      }

      final profileJson = rows.first['profile_json'];
      if (profileJson is! String) {
        await _limparPerfilSilenciosamente();
        return null;
      }

      try {
        final decoded = jsonDecode(profileJson);

        if (decoded is Map<String, dynamic>) {
          return decoded;
        }

        await _limparPerfilSilenciosamente();
        return null;
      } on FormatException {
        await _limparPerfilSilenciosamente();
        return null;
      }
    } on BaseDadosException {
      rethrow;
    } catch (_) {
      throw const BaseDadosException('read_profile_failed');
    }
  }

  Future<void> limparPerfil() async {
    try {
      final db = await _db;

      await db.delete(
        _perfilTable,
        where: 'cache_id = ?',
        whereArgs: const [1],
      );
    } catch (_) {
      throw const BaseDadosException('clear_profile_failed');
    }
  }

  Future<void> substituirBadges(
    List<Map<String, dynamic>> badges,
  ) async {
    final cachedAt = DateTime.now().toUtc().toIso8601String();
    final rows = <Map<String, dynamic>>[];

    try {
      for (final badge in badges) {
        final idBadge = _toIntOrNull(badge['id_badge']);
        final titulo = _toStringOrNull(badge['nome_badge']);

        if (idBadge == null || titulo == null) {
          throw const BaseDadosException('invalid_badges');
        }

        final area = _toMapOrNull(badge['area']);
        final nivel = _toMapOrNull(badge['nivel']);

        rows.add({
          'badge_id': idBadge,
          'titulo': titulo,
          'descricao': _toStringOrNull(badge['descricao_badge']),
          'imagem': _toStringOrNull(badge['imagem']),
          'especial': _toBool(badge['especial']) ? 1 : 0,
          'pontos': _toIntOrNull(badge['pontos_badge']),
          'validade': _toIntOrNull(badge['validade']),
          'area_id': _toIntOrNull(area?['id_area']),
          'area_nome': _toStringOrNull(area?['nome_area']),
          'nivel_id': _toIntOrNull(nivel?['id_nivel']),
          'nivel_nome': _toStringOrNull(nivel?['nome_nivel']),
          'minha_area': _toBool(badge['minha_area']) ? 1 : 0,
          'estado': _toStringOrNull(badge['estado']) ?? 'disponivel',
          'progresso': _toIntOrNull(badge['progresso']) ?? 0,
          'update_badge': _toStringOrNull(badge['update_badge']),
          'badge_json': jsonEncode(badge),
          'cached_at': cachedAt,
        });
      }
    } on BaseDadosException {
      rethrow;
    } catch (_) {
      throw const BaseDadosException('invalid_badges');
    }

    try {
      final db = await _db;

      await db.transaction((txn) async {
        await txn.delete(_badgesTable);

        for (final row in rows) {
          await txn.insert(
            _badgesTable,
            row,
            conflictAlgorithm: ConflictAlgorithm.replace,
          );
        }
      });
    } catch (_) {
      throw const BaseDadosException('save_badges_failed');
    }
  }

  Future<List<Map<String, dynamic>>> lerBadges() async {
    try {
      final db = await _db;
      final rows = await db.query(
        _badgesTable,
        orderBy:
            'especial DESC, minha_area DESC, area_nome ASC, nivel_id ASC, titulo ASC',
      );
      final badges = <Map<String, dynamic>>[];

      for (final row in rows) {
        final badgeId = row['badge_id'];
        final badgeJson = row['badge_json'];

        if (badgeJson is! String) {
          await _limparBadgeSilenciosamente(badgeId);
          continue;
        }

        try {
          final decoded = jsonDecode(badgeJson);

          if (decoded is Map<String, dynamic>) {
            badges.add(decoded);
          } else {
            await _limparBadgeSilenciosamente(badgeId);
          }
        } on FormatException {
          await _limparBadgeSilenciosamente(badgeId);
        }
      }

      return badges;
    } on BaseDadosException {
      rethrow;
    } catch (_) {
      throw const BaseDadosException('read_badges_failed');
    }
  }

  Future<void> limparBadges() async {
    try {
      final db = await _db;
      await db.delete(_badgesTable);
    } catch (_) {
      throw const BaseDadosException('clear_badges_failed');
    }
  }

  Future<void> close() async {
    final database = _database;

    if (database != null && database.isOpen) {
      await database.close();
    }

    _database = null;
    _openingDatabase = null;
  }

  Future<void> _limparPerfilSilenciosamente() async {
    try {
      await limparPerfil();
    } on BaseDadosException {}
  }

  Future<void> _limparBadgeSilenciosamente(Object? badgeId) async {
    final id = _toIntOrNull(badgeId);

    if (id == null) {
      return;
    }

    try {
      final db = await _db;
      await db.delete(
        _badgesTable,
        where: 'badge_id = ?',
        whereArgs: [id],
      );
    } catch (_) {}
  }

  int? _toIntOrNull(Object? value) {
    if (value is int) {
      return value;
    }

    if (value is num) {
      return value.toInt();
    }

    return null;
  }

  String? _toStringOrNull(Object? value) {
    if (value == null) {
      return null;
    }

    final stringValue = value.toString().trim();
    return stringValue.isEmpty ? null : stringValue;
  }

  bool _toBool(Object? value) {
    if (value is bool) {
      return value;
    }

    if (value is num) {
      return value == 1;
    }

    if (value is String) {
      final normalized = value.trim().toLowerCase();
      return normalized == 'true' || normalized == '1';
    }

    return false;
  }

  Map<String, dynamic>? _toMapOrNull(Object? value) {
    return value is Map<String, dynamic> ? value : null;
  }
}
