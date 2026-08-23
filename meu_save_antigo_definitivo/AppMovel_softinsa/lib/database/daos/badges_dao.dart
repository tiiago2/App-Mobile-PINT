import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
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
      where: 'id_badge = ? AND deleted_badge IS NOT 1',
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
      where: 'deleted_badge IS NOT 1',
    );
  }

  /// Batch upserts badges from sync.
  Future<void> upsertFromSync(List<Map<String, dynamic>> dados) async {
    final db = await DatabaseHelper.instance.database;
    final batch = db.batch();
    for (final raw in dados) {
      final idBadge = intOrNull(raw['id_badge'] ?? raw['badge_id'] ?? raw['id']);
      if (idBadge == null) {
        debugPrint('⚠️ [BadgesDao] Ignorado: id_badge é nulo');
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
        'id_area': intOrNull(raw['id_area'] ?? raw['area_id'] ?? (raw['area'] is Map ? (raw['area'] as Map)['id_area'] ?? (raw['area'] as Map)['id'] : null)),
        'id_nivel': intOrNull(raw['id_nivel'] ?? raw['nivel_id'] ?? (raw['nivel'] is Map ? (raw['nivel'] as Map)['id_nivel'] ?? (raw['nivel'] as Map)['id'] : null)),
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
      WHERE br.id_badge = ? AND r.deleted_requisito IS NULL
    ''',
      [badgeId],
    );
  }

  /// Query 4: Obter os badges conquistados pelo utilizador com os seus detalhes
  Future<List<Map<String, dynamic>>> obterBadgesConquistados(int userId) async {
    final db = await DatabaseHelper.instance.database;
    final rows = await db.rawQuery('''
      SELECT b.id_badge, b.nome_badge, b.imagem, b.pontos_badge, b.validade, rb.data_obtencao
      FROM ${DatabaseSchema.registoBadgesTable} rb
      INNER JOIN ${DatabaseSchema.badgesTable} b ON rb.id_badge = b.id_badge
      WHERE rb.id_utilizador = ? 
        AND (rb.deleted_registo IS NOT 1) 
        AND (b.deleted_badge IS NOT 1)
        AND (rb.expirado IS NOT 1 AND rb.expirado != 1)
    ''', [userId]);

    return rows.map((row) => {
      'id': row['id_badge'],
      'titulo': row['nome_badge'],
      'subtitulo': row['nome_badge'],
      'imagem': row['imagem'],
      'pontos': row['pontos_badge'],
      'dataAquisicao': row['data_obtencao'],
      'validadeDias': row['validade'],
      'estado': 'conquistados',
    }).toList();
  }

  /// Obtém o histórico completo de badges do utilizador (ativos e expirados)
  Future<List<Map<String, dynamic>>> obterHistoricoBadges(int userId) async {
    final db = await DatabaseHelper.instance.database;
    final rows = await db.rawQuery('''
      SELECT b.id_badge, b.nome_badge, b.imagem, b.pontos_badge, b.validade, rb.data_obtencao
      FROM ${DatabaseSchema.registoBadgesTable} rb
      INNER JOIN ${DatabaseSchema.badgesTable} b ON rb.id_badge = b.id_badge
      WHERE rb.id_utilizador = ? 
        AND (rb.deleted_registo IS NOT 1) 
        AND (b.deleted_badge IS NOT 1)
      ORDER BY rb.data_obtencao DESC
    ''', [userId]);

    return rows.map((row) => {
      'id': row['id_badge'],
      'titulo': row['nome_badge'],
      'subtitulo': row['nome_badge'],
      'imagem': row['imagem'],
      'pontos': row['pontos_badge'],
      'dataAquisicao': row['data_obtencao'],
      'validadeDias': row['validade'],
    }).toList();
  }

  Future<List<Map<String, dynamic>>> obterTodosBadgesParaGaleria({
    required int userId,
    required int userAreaId,
  }) async {
    final db = await DatabaseHelper.instance.database;
    final rows = await db.rawQuery('''
      SELECT b.id_badge, b.nome_badge, b.descricao_badge, b.validade, b.imagem, b.especial, b.pontos_badge as pontos,
             a.nome_area as areaNome, n.nome_nivel as nivelNome, b.id_nivel as nivelId,
             sl.nome_service_line as serviceLineNome, sl.id_service_line as serviceLineId,
             lp.nome_learning_path as learningPathNome, lp.id_learning_path as learningPathId,
             CASE WHEN b.id_area = ? THEN 1 ELSE 0 END as minha_area,
             (SELECT COUNT(*) FROM ${DatabaseSchema.badgesRequisitosTable} br WHERE br.id_badge = b.id_badge) as total_requisitos,
             (SELECT COUNT(DISTINCT r.id_requisito)
              FROM ${DatabaseSchema.badgesRequisitosTable} br2
              INNER JOIN ${DatabaseSchema.requisitosTable} r ON br2.id_requisito = r.id_requisito
              INNER JOIN ${DatabaseSchema.submissoesTable} s2 ON s2.id_badge = br2.id_badge
              LEFT JOIN ${DatabaseSchema.submissaoRequisitosTable} sr ON sr.id_submissao_local = s2.id_submissao_local AND sr.id_requisito = r.id_requisito
              LEFT JOIN ${DatabaseSchema.documentosSubmissaoTable} ds ON ds.id_submissao_local = s2.id_submissao_local AND ds.id_requisito = r.id_requisito
              WHERE s2.id_utilizador = ? 
                AND s2.id_badge = b.id_badge
                AND LOWER(TRIM(s2.status)) IN ('draft', 'submitted', 'rascunho', 'submetida_pendente', 'em_progresso', 'pendente')
                AND s2.deleted_submissao IS NOT 1
                AND (
                  (sr.estado_local = 'uploaded' OR sr.estado_local = 'approved')
                  OR (ds.id_ficheiro_local IS NOT NULL AND (ds.deleted_file IS NULL OR ds.deleted_file != 1))
                )
             ) as requisitos_completos,
             COALESCE(
               (SELECT 'conquistados' 
                FROM ${DatabaseSchema.registoBadgesTable} rb 
                WHERE rb.id_utilizador = ? AND rb.id_badge = b.id_badge AND (rb.deleted_registo IS NOT 1)
                  AND (rb.expirado IS NOT 1 AND rb.expirado != 1)
                  AND (b.validade IS NULL OR datetime(rb.data_obtencao, '+' || b.validade || ' day') >= datetime('now'))
                ORDER BY rb.data_obtencao DESC, rb.id_registo DESC
                LIMIT 1),
               (SELECT CASE 
                         WHEN LOWER(TRIM(s.status)) IN ('rascunho', 'draft', 'em_progresso', 'emprogresso') THEN 'emProgresso'
                         WHEN LOWER(TRIM(s.status)) IN ('submetida_pendente', 'pendente', 'submitted', 'aceite talent') THEN 'pendentes'
                         WHEN LOWER(TRIM(s.status)) IN ('rejeitado', 'rejeitada', 'reprovado', 'reprovada', 'recusado', 'recusada', 'rejected') THEN 'recusados'
                         ELSE 'disponivel'
                       END
                FROM ${DatabaseSchema.submissoesTable} s
                WHERE s.id_utilizador = ? AND s.id_badge = b.id_badge 
                  AND (s.deleted_submissao = 0 OR s.deleted_submissao IS NULL OR s.deleted_submissao = '0' OR s.deleted_submissao = 'false')
                ORDER BY s.id_submissao_local DESC
                LIMIT 1),
               (SELECT 'expirados' 
                FROM ${DatabaseSchema.registoBadgesTable} rb 
                WHERE rb.id_utilizador = ? AND rb.id_badge = b.id_badge AND (rb.deleted_registo IS NOT 1)
                  AND (rb.expirado = 1 OR (b.validade IS NOT NULL AND datetime(rb.data_obtencao, '+' || b.validade || ' day') < datetime('now')))
                ORDER BY rb.data_obtencao DESC, rb.id_registo DESC
                LIMIT 1),
               'disponivel'
             ) as estado
      FROM ${DatabaseSchema.badgesTable} b
      LEFT JOIN ${DatabaseSchema.areasTable} a ON b.id_area = a.id_area
      LEFT JOIN ${DatabaseSchema.niveisTable} n ON b.id_nivel = n.id_nivel
      LEFT JOIN ${DatabaseSchema.serviceLinesTable} sl ON a.id_service_line = sl.id_service_line
      LEFT JOIN ${DatabaseSchema.learningPathsTable} lp ON sl.id_learning_path = lp.id_learning_path
      WHERE (b.deleted_badge IS NOT 1)
    ''', [userAreaId, userId, userId, userId, userId]);

    return rows.map((row) {
      final isEspecial = (row['especial'] == 1 || row['especial'] == true);
      final isMinhaArea = (row['minha_area'] == 1 || row['minha_area'] == true);
      final total = row['total_requisitos'] as int? ?? 0;
      final completos = row['requisitos_completos'] as int? ?? 0;
      final progressPercentage = total > 0 ? ((completos / total) * 100).toInt() : 0;

      return {
        'id_badge': row['id_badge'],
        'id': row['id_badge'],
        'titulo': row['nome_badge'] ?? '',
        'nome_badge': row['nome_badge'] ?? '',
        'title': row['nome_badge'] ?? '',
        'descricao': row['descricao_badge'] ?? '',
        'descricao_badge': row['descricao_badge'] ?? '',
        'imagem': row['imagem'],
        'especial': isEspecial,
        'minha_area': isMinhaArea,
        'minhaArea': isMinhaArea,
        'estado': row['estado'] ?? 'disponivel',
        'status': row['estado'] ?? 'disponivel',
        'progresso': progressPercentage,
        'areaNome': row['areaNome'] ?? 'Geral',
        'area': row['areaNome'] ?? 'Geral',
        'categoria': row['areaNome'] ?? 'Geral',
        'nivelNome': row['nivelNome'] ?? 'Básico',
        'nivel': row['nivelNome'] ?? 'Básico',
        'nivelId': row['nivelId'],
        'pontos': row['pontos'] ?? 0,
        'validade': row['validade'],
        'validadeDias': row['validade'] ?? 0,
        'serviceLineNome': row['serviceLineNome'],
        'serviceLineId': row['serviceLineId'],
        'learningPathNome': row['learningPathNome'],
        'learningPathId': row['learningPathId'],
      };
    }).toList();
  }

  /// Query Galeria B: Obter badges sugeridos locais (reproduzindo fn_sugerir_badges)
  Future<List<Map<String, dynamic>>> obterBadgesSugeridos({
    required int userId,
    required int userAreaId,
  }) async {
    final db = await DatabaseHelper.instance.database;
    final rows = await db.rawQuery('''
      WITH
      registos_mais_recentes AS (
          SELECT id_registo, badge_id, id_utilizador, data_obtencao, expirado
          FROM (
              SELECT rb.id_registo, rb.id_badge AS badge_id, rb.id_utilizador, rb.data_obtencao, rb.expirado,
                     ROW_NUMBER() OVER (PARTITION BY rb.id_badge ORDER BY rb.data_obtencao DESC, rb.id_registo DESC) as rn
              FROM ${DatabaseSchema.registoBadgesTable} rb
              WHERE rb.id_utilizador = ? AND (rb.deleted_registo IS NOT 1)
          )
          WHERE rn = 1
      ),
      submissoes_mais_recentes AS (
          SELECT id_submissao, badge_id, status, data_submissao
          FROM (
              SELECT s.id_submissao, s.id_badge AS badge_id, s.status, s.data_submissao,
                     ROW_NUMBER() OVER (PARTITION BY s.id_badge ORDER BY s.data_submissao DESC, s.id_submissao DESC) as rn
              FROM ${DatabaseSchema.submissoesTable} s
              WHERE s.id_utilizador = ? AND (s.deleted_submissao IS NOT 1)
          )
          WHERE rn = 1
      ),
      candidaturas_abertas AS (
          SELECT smr.badge_id
          FROM submissoes_mais_recentes smr
          WHERE LOWER(TRIM(smr.status)) IN ('em_progresso', 'pendente', 'aceite talent', 'draft', 'submitted', 'rascunho', 'submetida_pendente')
      ),
      badges_validos AS (
          SELECT rmr.badge_id
          FROM registos_mais_recentes rmr
          INNER JOIN ${DatabaseSchema.badgesTable} b ON b.id_badge = rmr.badge_id
          WHERE b.deleted_badge IS NOT 1
            AND COALESCE(rmr.expirado, 0) = 0
            AND (
                  b.validade IS NULL
                  OR datetime(rmr.data_obtencao, '+' || b.validade || ' day') >= datetime('now')
            )
      ),
      sugestoes_expirados AS (
          SELECT rmr.badge_id, 1 AS prioridade, 'O teu badge expirou. Renova-o!' AS motivo
          FROM registos_mais_recentes rmr
          INNER JOIN ${DatabaseSchema.badgesTable} b ON b.id_badge = rmr.badge_id
          WHERE b.deleted_badge IS NOT 1
            AND (
                  COALESCE(rmr.expirado, 0) = 1
                  OR (
                      b.validade IS NOT NULL
                      AND datetime(rmr.data_obtencao, '+' || b.validade || ' day') < datetime('now')
                  )
            )
      ),
      sugestoes_nivel_seguinte AS (
          SELECT DISTINCT b.id_badge AS badge_id, 2 AS prioridade, 'Pronto para o próximo nível na tua área?' AS motivo
          FROM ${DatabaseSchema.badgesTable} b
          WHERE b.deleted_badge IS NOT 1
            AND EXISTS (
                  SELECT 1
                  FROM ${DatabaseSchema.badgesTable} b_atual
                  INNER JOIN badges_validos bv ON bv.badge_id = b_atual.id_badge
                  WHERE b.id_area = b_atual.id_area
                    AND b.id_nivel = b_atual.id_nivel + 1
                    AND b_atual.deleted_badge IS NOT 1
            )
            AND NOT EXISTS (SELECT 1 FROM badges_validos bv WHERE bv.badge_id = b.id_badge)
            AND NOT EXISTS (SELECT 1 FROM candidaturas_abertas ca WHERE ca.badge_id = b.id_badge)
      ),
      requisitos_aceites_consultor AS (
          SELECT DISTINCT d.id_requisito
          FROM ${DatabaseSchema.documentosSubmissaoTable} d
          INNER JOIN ${DatabaseSchema.submissoesTable} s ON s.id_submissao_local = d.id_submissao_local
          INNER JOIN ${DatabaseSchema.requisitosTable} r ON r.id_requisito = d.id_requisito
          WHERE s.id_utilizador = ?
            AND LOWER(TRIM(s.status)) IN ('aceite', 'approved')
            AND d.deleted_file IS NOT 1
            AND r.deleted_requisito IS NOT 1
      ),
      sugestoes_requisitos_reutilizaveis AS (
          SELECT DISTINCT b.id_badge AS badge_id, 3 AS prioridade, 'Podes reaproveitar evidências que já tens para obter este badge!' AS motivo
          FROM ${DatabaseSchema.badgesTable} b
          INNER JOIN ${DatabaseSchema.badgesRequisitosTable} rb_req ON rb_req.id_badge = b.id_badge
          INNER JOIN ${DatabaseSchema.requisitosTable} r ON r.id_requisito = rb_req.id_requisito AND r.deleted_requisito IS NOT 1
          INNER JOIN requisitos_aceites_consultor rac ON rac.id_requisito = rb_req.id_requisito
          WHERE b.deleted_badge IS NOT 1
            AND NOT EXISTS (SELECT 1 FROM badges_validos bv WHERE bv.badge_id = b.id_badge)
            AND NOT EXISTS (SELECT 1 FROM candidaturas_abertas ca WHERE ca.badge_id = b.id_badge)
      ),
      sugestoes_populares AS (
          SELECT b.id_badge AS badge_id, 4 AS prioridade, 'Em destaque entre os colegas' AS motivo
          FROM ${DatabaseSchema.badgesTable} b
          INNER JOIN ${DatabaseSchema.registoBadgesTable} rb ON rb.id_badge = b.id_badge
          WHERE b.deleted_badge IS NOT 1
            AND NOT EXISTS (SELECT 1 FROM badges_validos bv WHERE bv.badge_id = b.id_badge)
            AND NOT EXISTS (SELECT 1 FROM candidaturas_abertas ca WHERE ca.badge_id = b.id_badge)
          GROUP BY b.id_badge
      ),
      sugestoes_area_consultor AS (
          SELECT b.id_badge AS badge_id, 5 AS prioridade, 'Recomendado para a tua área profissional' AS motivo
          FROM ${DatabaseSchema.badgesTable} b
          WHERE b.deleted_badge IS NOT 1
            AND b.id_area = ?
            AND NOT EXISTS (SELECT 1 FROM badges_validos bv WHERE bv.badge_id = b.id_badge)
            AND NOT EXISTS (SELECT 1 FROM candidaturas_abertas ca WHERE ca.badge_id = b.id_badge)
      ),
      sugestoes_gerais_disponiveis AS (
          SELECT b.id_badge AS badge_id, 6 AS prioridade, 'Desenvolve novas competências' AS motivo
          FROM ${DatabaseSchema.badgesTable} b
          WHERE b.deleted_badge IS NOT 1
            AND NOT EXISTS (SELECT 1 FROM badges_validos bv WHERE bv.badge_id = b.id_badge)
            AND NOT EXISTS (SELECT 1 FROM candidaturas_abertas ca WHERE ca.badge_id = b.id_badge)
      ),
      todas_sugestoes AS (
          SELECT badge_id, prioridade, motivo FROM sugestoes_expirados
          UNION ALL
          SELECT badge_id, prioridade, motivo FROM sugestoes_nivel_seguinte
          UNION ALL
          SELECT badge_id, prioridade, motivo FROM sugestoes_requisitos_reutilizaveis
          UNION ALL
          SELECT badge_id, prioridade, motivo FROM sugestoes_populares
          UNION ALL
          SELECT badge_id, prioridade, motivo FROM sugestoes_area_consultor
          UNION ALL
          SELECT badge_id, prioridade, motivo FROM sugestoes_gerais_disponiveis
      ),
      sugestoes_numeradas AS (
          SELECT badge_id, prioridade, motivo,
                 ROW_NUMBER() OVER (PARTITION BY badge_id ORDER BY prioridade ASC) AS ordem_deduplicacao
          FROM todas_sugestoes
      ),
      sugestoes_limpas AS (
          SELECT badge_id, prioridade, motivo
          FROM sugestoes_numeradas
          WHERE ordem_deduplicacao = 1
      ),
      distribuicao AS (
          SELECT badge_id, prioridade, motivo,
                 ROW_NUMBER() OVER (PARTITION BY prioridade ORDER BY badge_id DESC) AS ordem_interna
          FROM sugestoes_limpas
      )
      SELECT
          d.badge_id AS id_badge,
          b.nome_badge AS titulo,
          b.especial,
          b.imagem,
          b.pontos_badge AS pontos,
          a.nome_area AS categoria,
          a.nome_area AS areaNome,
          n.nome_nivel AS nivelNome,
          b.id_nivel AS nivelId,
          d.motivo AS justificacao,
          (SELECT COUNT(*) FROM ${DatabaseSchema.badgesRequisitosTable} br WHERE br.id_badge = b.id_badge) as total_requisitos,
          (SELECT COUNT(DISTINCT r.id_requisito)
           FROM ${DatabaseSchema.badgesRequisitosTable} br2
           INNER JOIN ${DatabaseSchema.requisitosTable} r ON br2.id_requisito = r.id_requisito
           INNER JOIN ${DatabaseSchema.submissoesTable} s2 ON s2.id_badge = br2.id_badge
           LEFT JOIN ${DatabaseSchema.submissaoRequisitosTable} sr ON sr.id_submissao_local = s2.id_submissao_local AND sr.id_requisito = r.id_requisito
           LEFT JOIN ${DatabaseSchema.documentosSubmissaoTable} ds ON ds.id_submissao_local = s2.id_submissao_local AND ds.id_requisito = r.id_requisito
           WHERE s2.id_utilizador = ? 
             AND s2.id_badge = b.id_badge
             AND LOWER(TRIM(s2.status)) IN ('draft', 'submitted', 'rascunho', 'submetida_pendente', 'em_progresso', 'pendente')
             AND s2.deleted_submissao IS NOT 1
             AND (
               (sr.estado_local = 'uploaded' OR sr.estado_local = 'approved')
               OR (ds.id_ficheiro_local IS NOT NULL AND (ds.deleted_file IS NULL OR ds.deleted_file != 1))
             )
          ) as requisitos_completos,
          COALESCE(
            (SELECT CASE 
                      WHEN rb2.expirado = 1 
                           OR (b.validade IS NOT NULL 
                               AND datetime(rb2.data_obtencao, '+' || b.validade || ' day') < datetime('now'))
                      THEN 'expirado' 
                      ELSE 'obtido' 
                    END 
             FROM ${DatabaseSchema.registoBadgesTable} rb2 
             WHERE rb2.id_utilizador = ? AND rb2.id_badge = b.id_badge AND (rb2.deleted_registo IS NOT 1)
             ORDER BY rb2.data_obtencao DESC, rb2.id_registo DESC
             LIMIT 1),
             (SELECT CASE 
                       WHEN LOWER(TRIM(s3.status)) IN ('rascunho', 'draft', 'em_progresso') THEN 'emProgresso'
                       WHEN LOWER(TRIM(s3.status)) IN ('submetida_pendente', 'pendente', 'submitted', 'aceite talent') THEN 'emProgresso'
                       WHEN LOWER(TRIM(s3.status)) IN ('rejeitado', 'rejeitada', 'reprovado', 'reprovada', 'recusado', 'recusada', 'rejected') THEN 'disponivel'
                       ELSE 'disponivel'
                     END
             FROM ${DatabaseSchema.submissoesTable} s3
             WHERE s3.id_utilizador = ? AND s3.id_badge = b.id_badge AND (s3.deleted_submissao IS NOT 1)
             ORDER BY s3.id_submissao_local DESC
             LIMIT 1),
            'disponivel'
          ) as estado
      FROM distribuicao d
      INNER JOIN ${DatabaseSchema.badgesTable} b ON b.id_badge = d.badge_id
      LEFT JOIN ${DatabaseSchema.areasTable} a ON b.id_area = a.id_area
      LEFT JOIN ${DatabaseSchema.niveisTable} n ON b.id_nivel = n.id_nivel
      WHERE b.id_badge NOT IN (
        SELECT rb.id_badge 
        FROM ${DatabaseSchema.registoBadgesTable} rb 
        WHERE rb.id_utilizador = ? AND rb.expirado = 0 AND (rb.deleted_registo IS NOT 1)
      )
      ORDER BY
          d.ordem_interna ASC,
          d.prioridade ASC
      LIMIT 8
    ''', [userId, userId, userId, userAreaId, userId, userId, userId, userId]);

    return rows.map((row) {
      final total = row['total_requisitos'] as int? ?? 0;
      final completos = row['requisitos_completos'] as int? ?? 0;
      final progressPercentage = total > 0 ? ((completos / total) * 100).toInt() : 0;

      final isEspecial = (row['especial'] == 1 || row['especial'] == true);

      return {
        'id_badge': row['id_badge'],
        'titulo': row['titulo'] ?? '',
        'nome_badge': row['titulo'] ?? '',
        'especial': isEspecial,
        'imagem': row['imagem'],
        'pontos': row['pontos'] ?? 0,
        'categoria': row['categoria'] ?? 'Geral',
        'areaNome': row['areaNome'] ?? 'Geral',
        'nivelNome': row['nivelNome'] ?? '',
        'nivelId': row['nivelId'],
        'estado': row['estado'] ?? 'disponivel',
        'justificacao': row['justificacao'] ?? '',
        'progresso': progressPercentage,
      };
    }).toList();
  }

  Future<String> obterEstadoDeUmBadge(int userId, int badgeId) async {
    final db = await DatabaseHelper.instance.database;
    final rows = await db.rawQuery('''
      SELECT COALESCE(
        (SELECT 'conquistados' 
         FROM ${DatabaseSchema.registoBadgesTable} rb 
         INNER JOIN ${DatabaseSchema.badgesTable} b ON b.id_badge = rb.id_badge
         WHERE rb.id_utilizador = ? AND rb.id_badge = ? AND (rb.deleted_registo IS NOT 1)
           AND (rb.expirado IS NOT 1 AND rb.expirado != 1)
           AND (b.validade IS NULL OR datetime(rb.data_obtencao, '+' || b.validade || ' day') >= datetime('now'))
         ORDER BY rb.data_obtencao DESC, rb.id_registo DESC
         LIMIT 1),
        (SELECT CASE 
                  WHEN LOWER(TRIM(s.status)) IN ('rascunho', 'draft', 'em_progresso', 'emprogresso') THEN 'emProgresso'
                  WHEN LOWER(TRIM(s.status)) IN ('submetida_pendente', 'pendente', 'submitted', 'aceite talent') THEN 'pendentes'
                  WHEN LOWER(TRIM(s.status)) IN ('rejeitado', 'rejeitada', 'reprovado', 'reprovada', 'recusado', 'recusada', 'rejected') THEN 'recusados'
                  ELSE 'disponivel'
                END
         FROM ${DatabaseSchema.submissoesTable} s
         WHERE s.id_utilizador = ? AND s.id_badge = ? 
           AND (s.deleted_submissao = 0 OR s.deleted_submissao IS NULL OR s.deleted_submissao = '0' OR s.deleted_submissao = 'false')
         ORDER BY s.id_submissao_local DESC
         LIMIT 1),
        (SELECT 'expirados' 
         FROM ${DatabaseSchema.registoBadgesTable} rb 
         INNER JOIN ${DatabaseSchema.badgesTable} b ON b.id_badge = rb.id_badge
         WHERE rb.id_utilizador = ? AND rb.id_badge = ? AND (rb.deleted_registo IS NOT 1)
           AND (rb.expirado = 1 OR (b.validade IS NOT NULL AND datetime(rb.data_obtencao, '+' || b.validade || ' day') < datetime('now')))
         ORDER BY rb.data_obtencao DESC, rb.id_registo DESC
         LIMIT 1),
        'disponivel'
      ) as estado
    ''', [userId, badgeId, userId, badgeId, userId, badgeId]);
    
    if (rows.isNotEmpty) {
      return rows.first['estado']?.toString() ?? 'disponivel';
    }
    return 'disponivel';
  }
}

typedef BadgeDao = BadgesDao;
