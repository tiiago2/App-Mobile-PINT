import 'dart:async';
import 'package:sqflite/sqflite.dart';
import '../database_helper.dart';
import '../database_schema.dart';
import '../sync_helpers.dart';

class PermissoesDao {
  PermissoesDao._();
  static final PermissoesDao instance = PermissoesDao._();

  final _changes = StreamController<int>.broadcast();
  Stream<int> get changes => _changes.stream;

  /// Retrieves all permissions from the local database.
  Future<List<Map<String, dynamic>>> obterTodasPermissoes() async {
    final db = await DatabaseHelper.instance.database;
    return db.query(
      DatabaseSchema.permissoesTable,
      where: 'deleted_permissao IS NOT 1',
      orderBy: 'id_permissao ASC',
    );
  }

  /// Verifica se uma determinada permissão tem o toggle ativo (toggle == 1).
  /// Retorna true se toggle == 1, false se toggle == 0.
  Future<bool> verificarPermissao({int? idPermissao, String? termo}) async {
    final db = await DatabaseHelper.instance.database;
    String where = 'deleted_permissao IS NOT 1';
    final List<dynamic> args = [];

    if (idPermissao != null) {
      where += ' AND id_permissao = ?';
      args.add(idPermissao);
    } else if (termo != null && termo.trim().isNotEmpty) {
      where += ' AND (LOWER(descricao_permissao) LIKE ? OR LOWER(scope_json) LIKE ?)';
      final pattern = '%${termo.trim().toLowerCase()}%';
      args.add(pattern);
      args.add(pattern);
    }

    final rows = await db.query(
      DatabaseSchema.permissoesTable,
      where: where,
      whereArgs: args,
    );

    if (rows.isEmpty) {
      return true;
    }

    return rows.any((r) => r['toggle'] == 1 || r['toggle'] == true);
  }

  /// Verifica se o utilizador tem permissão para carregar/anexar ficheiros (toggle == 1).
  Future<bool> podeCarregarFicheiros() async {
    final db = await DatabaseHelper.instance.database;
    final rows = await db.query(
      DatabaseSchema.permissoesTable,
      where: "(LOWER(descricao_permissao) LIKE '%upload%' OR LOWER(descricao_permissao) LIKE '%anexar%' OR LOWER(descricao_permissao) LIKE '%evidencia%' OR LOWER(descricao_permissao) LIKE '%documento%' OR LOWER(scope_json) LIKE '%upload%') AND deleted_permissao IS NOT 1",
    );

    if (rows.isEmpty) {
      final allRows = await db.query(
        DatabaseSchema.permissoesTable,
        where: 'deleted_permissao IS NOT 1',
      );
      if (allRows.isEmpty) return true;
      return allRows.any((r) => r['toggle'] == 1 || r['toggle'] == true);
    }

    return rows.any((r) => r['toggle'] == 1 || r['toggle'] == true);
  }

  /// Verifica se o utilizador tem permissão para descarregar ficheiros (toggle == 1).
  Future<bool> podeDescarregarFicheiros() async {
    final db = await DatabaseHelper.instance.database;
    final rows = await db.query(
      DatabaseSchema.permissoesTable,
      where: "(LOWER(descricao_permissao) LIKE '%download%' OR LOWER(descricao_permissao) LIKE '%descarregar%' OR LOWER(descricao_permissao) LIKE '%ficheiro%' OR LOWER(scope_json) LIKE '%download%') AND deleted_permissao IS NOT 1",
    );

    if (rows.isEmpty) {
      final allRows = await db.query(
        DatabaseSchema.permissoesTable,
        where: 'deleted_permissao IS NOT 1',
      );
      if (allRows.isEmpty) return true;
      return allRows.any((r) => r['toggle'] == 1 || r['toggle'] == true);
    }

    return rows.any((r) => r['toggle'] == 1 || r['toggle'] == true);
  }

  /// Verifica se o utilizador tem permissão para partilhar externamente / LinkedIn (toggle == 1).
  Future<bool> podePartilhar() async {
    final db = await DatabaseHelper.instance.database;
    final rows = await db.query(
      DatabaseSchema.permissoesTable,
      where: "(LOWER(descricao_permissao) LIKE '%partilha%' OR LOWER(descricao_permissao) LIKE '%linkedin%' OR LOWER(scope_json) LIKE '%share%') AND deleted_permissao IS NOT 1",
    );

    if (rows.isEmpty) {
      final allRows = await db.query(
        DatabaseSchema.permissoesTable,
        where: 'deleted_permissao IS NOT 1',
      );
      if (allRows.isEmpty) return true;
      return allRows.any((r) => r['toggle'] == 1 || r['toggle'] == true);
    }

    return rows.any((r) => r['toggle'] == 1 || r['toggle'] == true);
  }

  /// Batch upserts permissions from sync.
  Future<void> upsertFromSync(List<Map<String, dynamic>> dados) async {
    final db = await DatabaseHelper.instance.database;
    final batch = db.batch();
    for (final raw in dados) {
      final idPermissao = intOrNull(raw['id_permissao'] ?? raw['id']);

      if (idPermissao == null) {
        print('⚠️ [PermissoesDao] Ignorado: id_permissao é nulo');
        continue;
      }

      final toggle = (raw['toggle'] == true || raw['toggle'] == 1) ? 1 : 0;
      final deletedPermissao = (raw['deleted_permissao'] == true || raw['deleted_permissao'] == 1) ? 1 : 0;

      batch.insert(
        DatabaseSchema.permissoesTable,
        {
          'id_permissao': idPermissao,
          'descricao_permissao': raw['descricao_permissao'] ?? raw['descricao'] ?? raw['permission_key'] ?? '',
          'toggle': toggle,
          'scope_json': raw['scope_json'],
          'updated_permissao': raw['updated_permissao']?.toString() ?? raw['updated_at']?.toString() ?? raw['server_updated_at']?.toString(),
          'deleted_permissao': deletedPermissao,
        },
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
    }
    await batch.commit(noResult: true);
    _changes.add(-1);
  }
}
