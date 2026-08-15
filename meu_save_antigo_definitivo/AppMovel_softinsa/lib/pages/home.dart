import 'package:flutter/material.dart';
import 'package:uicons/uicons.dart';
import 'package:go_router/go_router.dart';
import 'package:sqflite/sqflite.dart';
import '../variaveis/variaveis.dart';
import '../idiomas/app_localizations.dart';
import '../widgets/top_bar_actions.dart';
import '../widgets/galeria/badge_item_com_estado_wrapper.dart';
import 'badge_detalhe.dart';
import 'estatisticas.dart';
import '../database/database_helper.dart';
import '../database/daos/perfil_dao.dart';
import '../controllers/auth_controller.dart';
import '../database/sync_helpers.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  // ── Saudação Dinâmica ─────────────────────────────────────────────────────
  String _getGreeting(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final hour = DateTime.now().hour;
    if (hour < 12) {
      return l10n?.homeBomDia ?? 'Bom Dia!';
    } else if (hour < 20) {
      return l10n?.homeBoaTarde ?? 'Boa Tarde!';
    } else {
      return l10n?.homeBoaNoite ?? 'Boa Noite!';
    }
  }

  // ── Mocks da Home ──────────────────────────────────────────────────────────

  bool _isLoading = true;
  List<Map<String, dynamic>> _objetivosHome = [];
  List<Map<String, dynamic>> _badgesEmProgresso = [];
  List<Map<String, dynamic>> _ranking = [];

  @override
  void initState() {
    super.initState();
    _carregarDadosHome();
  }

  Future<void> _carregarDadosHome() async {
    try {
      final user = AuthController.instance.currentUser;
      final userId = intOrNull(user?['id'] ?? user?['user_id'] ?? user?['id_utilizador']);
      final db = await DatabaseHelper.instance.database;

      // 1. Objetivos Propostos Ativos (Não concluídos e Não expirados)
      final DateTime now = DateTime.now();
      final List<Map<String, dynamic>> objetivosHome = [];

      if (userId != null) {
        final objRows = await db.rawQuery('''
          SELECT o.id_objetivo_local, o.id_badge, o.data_final, o.data_conclusao,
                 b.nome_badge, b.id_area, b.imagem, b.especial, a.nome_area
          FROM objetivos o
          JOIN badges b ON o.id_badge = b.id_badge
          LEFT JOIN areas a ON b.id_area = a.id_area
          WHERE o.id_utilizador = ? AND o.deleted_objetivo = 0
        ''', [userId]);

        for (final r in objRows) {
          final dataConclusaoStr = r['data_conclusao']?.toString() ?? '';
          final concluido = dataConclusaoStr.isNotEmpty;

          if (!concluido) {
            final dataFinalStr = r['data_final']?.toString();
            final dataFinal = dataFinalStr != null ? DateTime.tryParse(dataFinalStr) : null;
            if (dataFinal != null) {
              final daysLeft = dataFinal.difference(now).inDays + 1;
              if (daysLeft > 0) {
                final badgeId = r['id_badge'];

                final subRes = await db.rawQuery('''
                  SELECT id_submissao, id_submissao_local
                  FROM submissoes
                  WHERE id_utilizador = ? AND id_badge = ?
                    AND (deleted_submissao = 0 OR deleted_submissao IS NULL OR deleted_submissao = 'false' OR deleted_submissao = '0')
                  LIMIT 1
                ''', [userId, badgeId]);

                double progress = 0.0;
                if (subRes.isNotEmpty) {
                  final sub = subRes.first;
                  final subId = sub['id_submissao'];
                  final subLocalId = sub['id_submissao_local'];

                  final reqsCountRes = await db.rawQuery('''
                    SELECT COUNT(*) as cnt FROM badges_requisitos WHERE id_badge = ?
                  ''', [badgeId]);
                  final totalReqs = Sqflite.firstIntValue(reqsCountRes) ?? 0;

                  final compReqsRes = await db.rawQuery('''
                    SELECT COUNT(DISTINCT id_requisito) as cnt
                    FROM documentos_submissao
                    WHERE (
                      (id_submissao IS NOT NULL AND id_submissao = ?) 
                      OR 
                      (id_submissao_local IS NOT NULL AND id_submissao_local = ?)
                    )
                    AND (deleted_file = 0 OR deleted_file IS NULL OR deleted_file = '')
                  ''', [subId, subLocalId]);
                  final compReqs = Sqflite.firstIntValue(compReqsRes) ?? 0;

                  if (totalReqs > 0) {
                    progress = compReqs / totalReqs;
                  }
                }

                final areaId = r['id_area'] as int? ?? 0;
                const areaColors = [
                  0xFF39639C,
                  0xFF5EA500,
                  0xFFE17100,
                  0xFF1C8CAE,
                  0xFFAE012F,
                  0xFF45556C,
                  0xFFE6900A,
                  0xFF805AD5,
                ];
                final cor = Color(areaColors[areaId % areaColors.length]);

                String deadlineFormatada = '';
                if (dataFinalStr != null && dataFinalStr.length >= 10) {
                  final partes = dataFinalStr.split(' ')[0].split('T')[0].split('-');
                  if (partes.length == 3) {
                    deadlineFormatada = '${partes[2]}/${partes[1]}/${partes[0]}';
                  } else {
                    deadlineFormatada = dataFinalStr;
                  }
                } else {
                  deadlineFormatada = dataFinalStr ?? '';
                }

                objetivosHome.add({
                  'titulo': r['nome_badge'] ?? '',
                  'categoria': r['nome_area'] ?? 'Geral',
                  'deadline': deadlineFormatada,
                  'diasRestantes': daysLeft,
                  'progresso': progress,
                  'avatarColor': cor,
                  'id_badge': badgeId,
                  'id': badgeId,
                  'imagem': r['imagem'],
                  'especial': r['especial'] == 1,
                });
              }
            }
          }
        }
      }

      // 2. Badges em Progresso (Candidaturas em progresso)
      final List<Map<String, dynamic>> badgesEmProgresso = [];
      if (userId != null) {
        final progRows = await db.rawQuery('''
          SELECT s.id_submissao, s.id_submissao_local, s.id_badge,
                 b.nome_badge, b.imagem, b.especial, b.id_area,
                 a.nome_area
          FROM submissoes s
          JOIN badges b ON s.id_badge = b.id_badge
          LEFT JOIN areas a ON b.id_area = a.id_area
          WHERE s.id_utilizador = ?
            AND s.status IN ('em_progresso', 'emprogresso', 'draft', 'rascunho')
            AND (s.deleted_submissao = 0 OR s.deleted_submissao IS NULL OR s.deleted_submissao = 'false' OR s.deleted_submissao = '0')
        ''', [userId]);

        for (final r in progRows) {
          final subId = r['id_submissao'];
          final subLocalId = r['id_submissao_local'];
          final badgeId = r['id_badge'];

          final reqsCountRes = await db.rawQuery('''
            SELECT COUNT(*) as cnt FROM badges_requisitos WHERE id_badge = ?
          ''', [badgeId]);
          final totalReqs = Sqflite.firstIntValue(reqsCountRes) ?? 0;

          final compReqsRes = await db.rawQuery('''
            SELECT COUNT(DISTINCT id_requisito) as cnt
            FROM documentos_submissao
            WHERE (
              (id_submissao IS NOT NULL AND id_submissao = ?) 
              OR 
              (id_submissao_local IS NOT NULL AND id_submissao_local = ?)
            )
            AND (deleted_file = 0 OR deleted_file IS NULL OR deleted_file = '')
          ''', [subId, subLocalId]);
          final compReqs = Sqflite.firstIntValue(compReqsRes) ?? 0;

          int progressPercent = 0;
          if (totalReqs > 0) {
            progressPercent = ((compReqs / totalReqs) * 100).round();
          }

          final areaId = r['id_area'] as int? ?? 0;
          const areaColors = [
            0xFF39639C,
            0xFF5EA500,
            0xFFE17100,
            0xFF1C8CAE,
            0xFFAE012F,
            0xFF45556C,
            0xFFE6900A,
            0xFF805AD5,
          ];
          final cor = Color(areaColors[areaId % areaColors.length]);

          badgesEmProgresso.add({
            'id_badge': badgeId,
            'id': badgeId,
            'titulo': r['nome_badge'] ?? '',
            'nome_badge': r['nome_badge'] ?? '',
            'categoria': r['nome_area'] ?? 'Geral',
            'estado': 'emProgresso',
            'progresso': progressPercent,
            'especial': r['especial'] == 1,
            'imagem': r['imagem'],
            'avatarColor': cor,
          });
        }
      }

      // 3. Classificação Geral (Leaderboard real do SQLite)
      final ouRows = await db.rawQuery('''
        SELECT ou.id_utilizador, ou.nome_user, ou.imagem_perfil, ou.pontos_semana, ou.pontos_mes, ou.pontos_ano, ou.pontos_totais, ou.ativo,
               a.nome_area
        FROM outros_users ou
        LEFT JOIN areas a ON ou.id_area = a.id_area
        WHERE ou.ativo = 1
      ''');

      final List<Map<String, dynamic>> todosUsers = [];
      for (final r in ouRows) {
        todosUsers.add({
          'id': r['id_utilizador'],
          'nome': r['nome_user'] ?? '',
          'area': r['nome_area'] ?? '',
          'service_line': '',
          'funcao': '',
          'pontos_semana': r['pontos_semana'] ?? 0,
          'pontos_mes': r['pontos_mes'] ?? 0,
          'pontos_ano': r['pontos_ano'] ?? 0,
          'pontos_sempre': r['pontos_totais'] ?? 0,
          'img': r['imagem_perfil'],
          'ativo': r['ativo'],
        });
      }

      if (userId != null) {
        final containsLogged = todosUsers.any((u) => u['id'] == userId);
        if (!containsLogged) {
          final perfilMap = await PerfilDao.instance.lerPerfilDoUtilizador(userId);
          if (perfilMap != null) {
            String areaNome = '';
            final areaId = perfilMap['area'];
            if (areaId != null) {
              final areaRow = await db.rawQuery('SELECT nome_area FROM areas WHERE id_area = ?', [areaId]);
              if (areaRow.isNotEmpty) areaNome = areaRow.first['nome_area']?.toString() ?? '';
            }

            todosUsers.add({
              'id': userId,
              'nome': perfilMap['nome'] ?? 'Eu',
              'area': areaNome,
              'service_line': '',
              'funcao': '',
              'pontos_semana': intOrNull(perfilMap['pontos_semana']) ?? 0,
              'pontos_mes': intOrNull(perfilMap['pontos_mes']) ?? 0,
              'pontos_ano': intOrNull(perfilMap['pontos_ano']) ?? 0,
              'pontos_sempre': intOrNull(perfilMap['pontos_totais']) ?? 0,
              'img': perfilMap['foto'],
              'ativo': 1,
            });
          }
        }
      }

      todosUsers.sort((a, b) => (b['pontos_sempre'] as int).compareTo(a['pontos_sempre'] as int));

      final List<Map<String, dynamic>> ranking = [];
      for (int i = 0; i < todosUsers.length; i++) {
        final u = todosUsers[i];
        ranking.add({
          'id': u['id'],
          'posicao': i + 1,
          'nome': u['nome'],
          'area': u['area'],
          'service_line': u['service_line'] ?? '',
          'funcao': u['funcao'] ?? '',
          'pontos_semana': u['pontos_semana'],
          'pontos_mes': u['pontos_mes'],
          'pontos_ano': u['pontos_ano'],
          'pontos_sempre': u['pontos_sempre'],
          'pontos': u['pontos_sempre'],
          'img': u['img'],
        });
      }

      debugPrint('🏠 [HomeScreen] CARREGAMENTO CONCLUÍDO!');
      debugPrint('   - Objetivos carregados: ${objetivosHome.length} -> $objetivosHome');
      debugPrint('   - Badges em progresso: ${badgesEmProgresso.length} -> $badgesEmProgresso');
      debugPrint('   - Ranking total: ${ranking.length}');

      if (mounted) {
        setState(() {
          _objetivosHome = objetivosHome;
          _badgesEmProgresso = badgesEmProgresso;
          _ranking = ranking;
          _isLoading = false;
        });
      }
    } catch (e, stack) {
      debugPrint('❌ [HomeScreen] Erro ao carregar dados: $e');
      debugPrint(stack.toString());
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  // ── Card de Objetivo Proposto (Horizontal) ────────────────────────────────
  Widget _buildHomeObjectiveCard(Map<String, dynamic> obj) {
    final String titulo = obj['titulo'] as String;
    final String categoria = obj['categoria'] as String;
    final String deadline = obj['deadline'] as String;
    final int diasRestantes = obj['diasRestantes'] as int;
    final double progresso = obj['progresso'] as double;
    final Color avatarColor = obj['avatarColor'] as Color;

    final String? imagem = obj['imagem'] as String?;
    final bool isEspecial = obj['especial'] == true;

    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => BadgeDetalheScreen(badge: obj),
          ),
        );
      },
      child: Container(
        width: 320,
        padding: const EdgeInsets.all(12.0),
        decoration: BoxDecoration(
          color: AppCores.branco,
          borderRadius: BorderRadius.circular(AppBorders.padrao),
          border: Border.all(color: AppCores.outline, width: 1.6),
        ),
        child: Row(
          children: [
            Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                color: avatarColor.withOpacity(0.15),
                shape: BoxShape.circle,
                border: isEspecial
                    ? Border.all(
                        color: const Color(0xFFF8AA0B),
                        width: 1.5,
                      )
                    : null,
              ),
              child: ClipOval(
                child: (imagem != null && imagem.isNotEmpty)
                    ? Image.network(
                        imagem,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) {
                          return Center(
                            child: Icon(
                              Icons.bolt_rounded,
                              color: avatarColor,
                              size: 28,
                            ),
                          );
                        },
                        loadingBuilder: (context, child, loadingProgress) {
                          if (loadingProgress == null) return child;
                          return Center(
                            child: SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(
                                strokeWidth: 1.5,
                                color: avatarColor,
                              ),
                            ),
                          );
                        },
                      )
                    : Center(
                        child: Icon(
                          Icons.bolt_rounded,
                          color: avatarColor,
                          size: 28,
                        ),
                      ),
              ),
            ),
            const SizedBox(width: 14.0),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              titulo,
                              style: const TextStyle(
                                color: AppCores.fontes,
                                fontSize: 14.0,
                                fontWeight: FontWeight.bold,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 2.0),
                            Text(
                              categoria,
                              style: TextStyle(
                                color: AppCores.fontes.withOpacity(0.5),
                                fontSize: 11.0,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 8.0),
                      Row(
                        children: [
                          Icon(
                            UIcons.boldRounded.calendar,
                            size: 13.0,
                            color: AppCores.fontes.withOpacity(0.6),
                          ),
                          const SizedBox(width: 4.0),
                          Text(
                            '$deadline • $diasRestantes dias',
                            style: TextStyle(
                              color: AppCores.fontes.withOpacity(0.8),
                              fontSize: 12.0,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 12.0),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(3.0),
                    child: LinearProgressIndicator(
                      value: progresso,
                      backgroundColor: const Color(0xFFF0F0F0),
                      valueColor: const AlwaysStoppedAnimation<Color>(
                        Color(0xFF62C884),
                      ),
                      minHeight: 6.0,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Podio (Top 3 Ranking) ─────────────────────────────────────────────────
  Widget _buildPodiumCard(Map<String, dynamic> user, int lugar) {
    Color borderColor;
    double cardHeight;
    double avatarSize;

    if (lugar == 1) {
      borderColor = const Color(0xFFF8AA0B); // Ouro
      cardHeight = 185;
      avatarSize = 52;
    } else if (lugar == 2) {
      borderColor = const Color(0xFFCAD5E2); // Prata
      cardHeight = 165;
      avatarSize = 44;
    } else {
      borderColor = const Color(0xFFD97706); // Bronze
      cardHeight = 155;
      avatarSize = 44;
    }

    return Container(
      height: cardHeight,
      padding: const EdgeInsets.symmetric(horizontal: 4.0, vertical: 8.0),
      decoration: BoxDecoration(
        color: AppCores.branco,
        borderRadius: BorderRadius.circular(16.0),
        border: Border.all(color: borderColor, width: 2.5),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: avatarSize,
            height: avatarSize,
            decoration: BoxDecoration(
              color: AppCores.outline.withOpacity(0.3),
              shape: BoxShape.circle,
            ),
            child: ClipOval(
              child: (user['img'] != null && (user['img'] as String).isNotEmpty)
                  ? Image.network(
                      user['img'] as String,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) {
                        return Icon(
                          UIcons.boldRounded.portrait,
                          color: AppCores.fontes,
                          size: avatarSize * 0.5,
                        );
                      },
                      loadingBuilder: (context, child, loadingProgress) {
                        if (loadingProgress == null) return child;
                        return Center(
                          child: SizedBox(
                            width: avatarSize * 0.4,
                            height: avatarSize * 0.4,
                            child: const CircularProgressIndicator(
                              strokeWidth: 1.5,
                              color: AppCores.azulFundo,
                            ),
                          ),
                        );
                      },
                    )
                  : Icon(
                      UIcons.boldRounded.portrait,
                      color: AppCores.fontes,
                      size: avatarSize * 0.5,
                    ),
            ),
          ),
          const SizedBox(height: 8.0),
          Text(
            user['nome'] as String,
            style: const TextStyle(
              color: AppCores.fontes,
              fontSize: 13.0,
              fontWeight: FontWeight.bold,
            ),
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 2.0),
          Text(
            user['area'] as String,
            style: TextStyle(
              color: AppCores.fontes.withOpacity(0.5),
              fontSize: 10.0,
            ),
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 6.0),
          Text(
            '${user['pontos']}',
            style: const TextStyle(
              color: AppCores.fontes,
              fontSize: 13.0,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  // ── Item da Lista de Ranking (Posições 4 a 10) ────────────────────────────
  Widget _buildRankingRowItem(Map<String, dynamic> user) {
    final int pos = user['posicao'] as int;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
      decoration: BoxDecoration(
        color: AppCores.branco,
        borderRadius: BorderRadius.circular(14.0),
        border: Border.all(color: AppCores.outline, width: 1.6),
      ),
      child: Row(
        children: [
          SizedBox(
            width: 28,
            child: Text(
              '$pos.',
              style: const TextStyle(
                color: AppCores.fontes,
                fontSize: 14.0,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: AppCores.outline.withOpacity(0.3),
              shape: BoxShape.circle,
            ),
            child: ClipOval(
              child: (user['img'] != null && (user['img'] as String).isNotEmpty)
                  ? Image.network(
                      user['img'] as String,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) {
                        return Icon(
                          UIcons.boldRounded.portrait,
                          color: AppCores.fontes,
                          size: 18,
                        );
                      },
                      loadingBuilder: (context, child, loadingProgress) {
                        if (loadingProgress == null) return child;
                        return const Center(
                          child: SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(
                              strokeWidth: 1.5,
                              color: AppCores.azulFundo,
                            ),
                          ),
                        );
                      },
                    )
                  : Icon(
                      UIcons.boldRounded.portrait,
                      color: AppCores.fontes,
                      size: 18,
                    ),
            ),
          ),
          const SizedBox(width: 12.0),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  user['nome'] as String,
                  style: const TextStyle(
                    color: AppCores.fontes,
                    fontSize: 14.0,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Text(
                  user['area'] as String,
                  style: TextStyle(
                    color: AppCores.fontes.withOpacity(0.5),
                    fontSize: 11.0,
                  ),
                ),
              ],
            ),
          ),
          Text(
            '${user['pontos']}',
            style: const TextStyle(
              color: AppCores.fontes,
              fontSize: 14.0,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  // ── Build ─────────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        backgroundColor: AppCores.branco,
        body: Center(
          child: CircularProgressIndicator(
            color: AppCores.azulFundo,
          ),
        ),
      );
    }

    final l10n = AppLocalizations.of(context)!;
    final top1 = _ranking.firstWhere((u) => u['posicao'] == 1, orElse: () => {'nome': '-', 'area': '-', 'pontos': 0, 'img': null, 'posicao': 1});
    final top2 = _ranking.firstWhere((u) => u['posicao'] == 2, orElse: () => {'nome': '-', 'area': '-', 'pontos': 0, 'img': null, 'posicao': 2});
    final top3 = _ranking.firstWhere((u) => u['posicao'] == 3, orElse: () => {'nome': '-', 'area': '-', 'pontos': 0, 'img': null, 'posicao': 3});
    
    final restoRanking = _ranking.where((u) => (u['posicao'] as int) > 3).toList();
    // Limita o ranking a no máximo 10 posições no total (ou seja, 7 itens nas posições 4-10)
    final limitedRestoRanking = restoRanking.take(7).toList();

    return Scaffold(
      backgroundColor: AppCores.branco,
      appBar: AppBar(
        backgroundColor: AppCores.branco,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        centerTitle: false,
        titleSpacing: AppTamanhos.colocacao_titulo,
        title: Text(
          _getGreeting(context),
          style: const TextStyle(
            color: AppCores.fontes,
            fontSize: AppTamanhos.titulo,
          ),
        ),
        actions: const [
          TopBarActions(),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _carregarDadosHome,
        color: AppCores.azulFundo,
        backgroundColor: AppCores.branco,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ── 1. Objetivos Propostos (Rolamento Horizontal) ────────────
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: AppTamanhos.margemEcra),
                  child: Text(
                    l10n.objetivosPropostos,
                    style: const TextStyle(
                      color: AppCores.fontes,
                      fontSize: AppTamanhos.titulo,
                    ),
                  ),
                ),
                const SizedBox(height: 12.0),
                SizedBox(
                  height: 96,
                  child: _objetivosHome.isEmpty
                      ? Center(
                          child: Text(
                            'Sem objetivos propostos ativos.',
                            style: TextStyle(
                              color: AppCores.fontes.withOpacity(0.5),
                              fontSize: 13.0,
                            ),
                          ),
                        )
                      : ListView.separated(
                          scrollDirection: Axis.horizontal,
                          padding: const EdgeInsets.symmetric(horizontal: AppTamanhos.margemEcra),
                          itemCount: _objetivosHome.length,
                          separatorBuilder: (_, __) => const SizedBox(width: 12.0),
                          itemBuilder: (context, index) {
                            return _buildHomeObjectiveCard(_objetivosHome[index]);
                          },
                        ),
                ),
                const SizedBox(height: 28.0),
  
                // ── 2. Badges em Progresso (Rolamento Horizontal) ─────────────
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: AppTamanhos.margemEcra),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        l10n.badgesEmProgresso,
                        style: const TextStyle(
                          color: AppCores.fontes,
                          fontSize: AppTamanhos.titulo,
                        ),
                      ),
                      IconButton(
                        icon: Icon(
                          UIcons.boldRounded.expand,
                          color: AppCores.fontes,
                          size: 20.0,
                        ),
                        onPressed: () {
                          context.go('/galeria?filtro=emProgresso');
                        },
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12.0),
                SizedBox(
                  height: 135,
                  child: _badgesEmProgresso.isEmpty
                      ? Center(
                          child: Text(
                            'Sem badges em progresso.',
                            style: TextStyle(
                              color: AppCores.fontes.withOpacity(0.5),
                              fontSize: 13.0,
                            ),
                          ),
                        )
                      : ListView.separated(
                          scrollDirection: Axis.horizontal,
                          padding: const EdgeInsets.symmetric(horizontal: AppTamanhos.margemEcra),
                          itemCount: _badgesEmProgresso.length,
                          separatorBuilder: (_, __) => const SizedBox(width: 16.0),
                          itemBuilder: (context, index) {
                            return BadgeItemComEstadoWrapper(
                              badge: _badgesEmProgresso[index],
                            );
                          },
                        ),
                ),
                const SizedBox(height: 28.0),
  
                // ── 3. Classificação Geral (Leaderboard / Ranking) ─────────────
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: AppTamanhos.margemEcra),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        l10n.classificacaoGeral,
                        style: const TextStyle(
                          color: AppCores.fontes,
                          fontSize: AppTamanhos.titulo,
                        ),
                      ),
                      IconButton(
                        icon: Icon(
                          UIcons.boldRounded.expand,
                          color: AppCores.fontes,
                          size: 20.0,
                        ),
                        onPressed: () {
                          showModalBottomSheet(
                            context: context,
                            isScrollControlled: true,
                            backgroundColor: Colors.transparent,
                            builder: (_) => ClassificacaoModal(dados: _ranking),
                          );
                        },
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16.0),
                // Pódio (Top 3)
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: AppTamanhos.margemEcra),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Expanded(child: _buildPodiumCard(top2, 2)),
                      const SizedBox(width: 8.0),
                      Expanded(child: _buildPodiumCard(top1, 1)),
                      const SizedBox(width: 8.0),
                      Expanded(child: _buildPodiumCard(top3, 3)),
                    ],
                  ),
                ),
                const SizedBox(height: 20.0),
                // Posições 4 a 10
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: AppTamanhos.margemEcra),
                  child: ListView.separated(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: limitedRestoRanking.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 10.0),
                    itemBuilder: (context, index) {
                      return _buildRankingRowItem(limitedRestoRanking[index]);
                    },
                  ),
                ),
                const SizedBox(height: 32.0),
                // Footer políticas RGPD
                Center(
                  child: Text(
                    'Políticas RGPD',
                    style: TextStyle(
                      color: AppCores.fontes.withOpacity(0.5),
                      fontSize: 12.0,
                      decoration: TextDecoration.underline,
                    ),
                  ),
                ),
                const SizedBox(height: 16.0),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
