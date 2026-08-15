import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
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
      where: 'id_requisito = ? AND deleted_requisito IS NOT 1',
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
      where: 'deleted_requisito IS NOT 1',
    );
  }

  /// Batch upserts requirements from sync.
  Future<void> upsertFromSync(List<Map<String, dynamic>> dados) async {
    final db = await DatabaseHelper.instance.database;
    final batch = db.batch();
    for (final raw in dados) {
      final requisitoId = intOrNull(raw['id_requisito'] ?? raw['requisito_id'] ?? raw['id']);
      if (requisitoId == null) {
        debugPrint('⚠️ [RequisitosDao] Ignorado: id_requisito é nulo');
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

  /// Obtém todos os requisitos de um badge e calcula se o utilizador já os cumpriu ou não.
  Future<List<Map<String, dynamic>>> obterRequisitosComEstado({
    required int badgeId,
    required int userId,
  }) async {
    final db = await DatabaseHelper.instance.database;
    final rows = await db.rawQuery('''
      SELECT r.id_requisito, r.nome_requisito, r.descricao_requisito,
             -- 1. Verifica se o badge inteiro está obtido pelo utilizador
             (SELECT COUNT(*) FROM ${DatabaseSchema.registoBadgesTable} rb 
              WHERE rb.id_badge = br.id_badge 
                AND rb.id_utilizador = ? 
                AND rb.expirado = 0 
                AND (rb.deleted_registo IS NOT 1)
             ) > 0 AS obtido,
             -- 2. Verifica se este requisito específico foi cumprido na submissão ativa
             (SELECT COUNT(*) FROM ${DatabaseSchema.submissaoRequisitosTable} sr
              INNER JOIN ${DatabaseSchema.submissoesTable} s ON s.id_submissao_local = sr.id_submissao_local
              WHERE s.id_badge = br.id_badge 
                AND s.id_utilizador = ? 
                AND sr.id_requisito = r.id_requisito
                AND (s.deleted_submissao IS NOT 1)
                AND (sr.estado_local = 'uploaded' OR sr.estado_local = 'approved')
             ) > 0 AS submetido
      FROM ${DatabaseSchema.requisitosTable} r
      INNER JOIN ${DatabaseSchema.badgesRequisitosTable} br ON r.id_requisito = br.id_requisito
      WHERE br.id_badge = ? AND (r.deleted_requisito IS NOT 1)
    ''', [userId, userId, badgeId]);

    return rows.map((row) {
      final obtido = row['obtido'] == 1 || row['obtido'] == true || row['obtido'] == '1';
      final submetido = row['submetido'] == 1 || row['submetido'] == true || row['submetido'] == '1';
      return {
        'id_requisito': row['id_requisito'],
        'nome_requisito': row['nome_requisito'] ?? '',
        'descricao_requisito': row['descricao_requisito'] ?? '',
        'cumprido': (obtido || submetido),
      };
    }).toList();
  }

  /// Obtém o ID de um badge pelo seu nome (para suporte a badges de mocks).
  Future<int?> obterIdBadgePorNome(String nomeBadge) async {
    final db = await DatabaseHelper.instance.database;
    // 1. Correspondência exata
    var rows = await db.query(
      DatabaseSchema.badgesTable,
      columns: ['id_badge'],
      where: 'nome_badge = ? AND deleted_badge IS NOT 1',
      whereArgs: [nomeBadge],
      limit: 1,
    );
    if (rows.isNotEmpty) return rows.first['id_badge'] as int?;

    // 2. Correspondência parcial (LIKE) para suporte a mocks (ex: "Low Code" encontra "Low Code Básico")
    rows = await db.query(
      DatabaseSchema.badgesTable,
      columns: ['id_badge'],
      where: 'nome_badge LIKE ? AND deleted_badge IS NOT 1',
      whereArgs: ['%$nomeBadge%'],
      limit: 1,
    );
    if (rows.isNotEmpty) return rows.first['id_badge'] as int?;

    return null;
  }
}
