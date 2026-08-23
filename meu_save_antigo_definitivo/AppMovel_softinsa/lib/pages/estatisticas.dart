import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:uicons/uicons.dart';
import 'package:sqflite/sqflite.dart';
import '../variaveis/variaveis.dart';
import '../idiomas/app_localizations.dart';
import '../widgets/top_bar_actions.dart';
import '../database/database_helper.dart';
import '../database/daos/perfil_dao.dart';
import '../controllers/auth_controller.dart';
import '../database/sync_helpers.dart';

class EstatisticasScreen extends StatefulWidget {
  const EstatisticasScreen({super.key});

  @override
  State<EstatisticasScreen> createState() => _EstatisticasScreenState();
}

class _EstatisticasScreenState extends State<EstatisticasScreen> {
  String _pointsPeriod = 'Mês';
  String _badgesPeriod = 'Trim';

  bool _isLoading = true;
  int _totalBadgesKpiValue = 0;
  String _lugarGeralKpiValue = '1.º';
  double _mediaProgressoKpiValue = 0.0;
  int _objetivosAtivosKpiValue = 0;

  List<Map<String, dynamic>> _listaClassificacao = [];
  List<Map<String, dynamic>> _distribuicaoBadges = [];
  List<Map<String, dynamic>> _distribuicaoNiveis = [];

  Map<String, List<Map<String, dynamic>>> _badgeEvolutionData = {
    'Sem': [],
    'Mês': [],
    'Trim': [],
    'Ano': [],
  };

  Map<String, List<Map<String, dynamic>>> _pointsEvolutionData = {
    'Sem': [],
    'Mês': [],
    'Trim': [],
    'Ano': [],
  };

  @override
  void initState() {
    super.initState();
    _carregarDadosReais();
  }

  Future<void> _carregarDadosReais() async {
    try {
      final user = AuthController.instance.currentUser;
      final userId = intOrNull(user?['id'] ?? user?['user_id'] ?? user?['id_utilizador']);
      final db = await DatabaseHelper.instance.database;

      // 1. KPI: Total de Badges (contar linhas da tabela badges onde deleted_badge = 0)
      final totalBadgesRes = await db.rawQuery('SELECT COUNT(*) as cnt FROM badges WHERE deleted_badge = 0');
      final totalBadges = Sqflite.firstIntValue(totalBadgesRes) ?? 0;

      // 2. Classificação Geral e Lugar Geral (outros_users ordenado por pontos_totais, associado a service_lines)
      final ouRows = await db.rawQuery('''
        SELECT ou.id_utilizador, ou.nome_user, ou.imagem_perfil, ou.pontos_semana, ou.pontos_mes, ou.pontos_ano, ou.pontos_totais, ou.ativo,
               a.nome_area, sl.nome_service_line
        FROM outros_users ou
        LEFT JOIN areas a ON ou.id_area = a.id_area
        LEFT JOIN service_lines sl ON a.id_service_line = sl.id_service_line
        WHERE ou.ativo = 1
      ''');

      final List<Map<String, dynamic>> todosUsers = [];
      for (final r in ouRows) {
        todosUsers.add({
          'id': r['id_utilizador'],
          'nome': r['nome_user'] ?? '',
          'area': r['nome_area'] ?? '',
          'service_line': r['nome_service_line'] ?? '',
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
            String serviceLineNome = '';
            final areaId = perfilMap['area'] ?? perfilMap['id_area'];
            if (areaId != null) {
              final areaRow = await db.rawQuery('''
                SELECT a.nome_area, sl.nome_service_line 
                FROM areas a
                LEFT JOIN service_lines sl ON a.id_service_line = sl.id_service_line
                WHERE a.id_area = ?
              ''', [areaId]);
              if (areaRow.isNotEmpty) {
                areaNome = areaRow.first['nome_area']?.toString() ?? '';
                serviceLineNome = areaRow.first['nome_service_line']?.toString() ?? '';
              }
            }

            todosUsers.add({
              'id': userId,
              'nome': perfilMap['nome'] ?? 'Eu',
              'area': areaNome,
              'service_line': serviceLineNome,
              'pontos_semana': 0,
              'pontos_mes': 0,
              'pontos_ano': 0,
              'pontos_sempre': intOrNull(perfilMap['pontos_totais']) ?? 0,
              'img': perfilMap['foto'],
              'ativo': 1,
            });
          }
        }
      }

      todosUsers.sort((a, b) => (b['pontos_sempre'] as int).compareTo(a['pontos_sempre'] as int));

      String lugarGeral = '-';
      if (userId != null) {
        final idx = todosUsers.indexWhere((u) => u['id'] == userId);
        if (idx != -1) {
          lugarGeral = '${idx + 1}.º';
        }
      }

      // 3. Distribuição de Badges por Área (agrupar a partir dos badges conquistados ativos do utilizador)
      final areaDistRows = await db.rawQuery('''
        SELECT b.id_area, a.nome_area, COUNT(rb.id_badge) as cnt
        FROM registo_badges rb
        INNER JOIN badges b ON rb.id_badge = b.id_badge
        INNER JOIN areas a ON b.id_area = a.id_area
        WHERE rb.id_utilizador = ?
          AND (rb.deleted_registo IS NOT 1)
          AND (rb.expirado = 0 OR rb.expirado IS NULL)
          AND (b.deleted_badge IS NOT 1)
        GROUP BY b.id_area, a.nome_area
      ''', [userId ?? 0]);

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

      final List<Map<String, dynamic>> distBadges = [];
      for (int i = 0; i < areaDistRows.length; i++) {
        final r = areaDistRows[i];
        distBadges.add({
          'Nome_Area': r['nome_area'] ?? 'Geral',
          'total_badges': r['cnt'] ?? 0,
          'cor': areaColors[i % areaColors.length],
        });
      }

      // 4. Distribuição por Níveis dos Badges do utilizador
      final niveisRows = await db.rawQuery('SELECT id_nivel, nome_nivel FROM niveis ORDER BY id_nivel ASC');
      final List<Map<String, dynamic>> distNiveis = [];
      const nivelColors = [
        0xFF5EA500,
        0xFF1C8CAE,
        0xFFE17100,
        0xFFAE012F,
        0xFF45556C,
      ];

      for (int i = 0; i < niveisRows.length; i++) {
        final n = niveisRows[i];
        final idNivel = n['id_nivel'];
        final nomeNivel = n['nome_nivel']?.toString() ?? '';

        int conquistadosCount = 0;
        if (userId != null) {
          final countRes = await db.rawQuery('''
            SELECT COUNT(*) as cnt
            FROM registo_badges rb
            JOIN badges b ON rb.id_badge = b.id_badge
            WHERE rb.id_utilizador = ?
              AND b.id_nivel = ?
              AND rb.expirado = 0
              AND rb.deleted_registo = 0
          ''', [userId, idNivel]);
          conquistadosCount = Sqflite.firstIntValue(countRes) ?? 0;
        }

        distNiveis.add({
          'label': nomeNivel,
          'value': conquistadosCount,
          'color': nivelColors[i % nivelColors.length],
        });
      }

      // 5. Média de Progresso
      double mediaProgresso = 0.0;
      if (userId != null) {
        final progSubmissoes = await db.rawQuery('''
          SELECT id_submissao, id_submissao_local, id_badge
          FROM submissoes
          WHERE id_utilizador = ?
            AND status IN ('em_progresso', 'emprogresso', 'draft', 'rascunho')
            AND (deleted_submissao = 0 OR deleted_submissao IS NULL OR deleted_submissao = 'false' OR deleted_submissao = '0')
        ''', [userId]);

        if (progSubmissoes.isNotEmpty) {
          double somaMedias = 0.0;
          for (final sub in progSubmissoes) {
            final subId = sub['id_submissao'];
            final subLocalId = sub['id_submissao_local'];
            final badgeId = sub['id_badge'];

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

            double progress = 0.0;
            if (totalReqs > 0) {
              progress = compReqs / totalReqs;
            } else {
              progress = 0.45;
            }
            somaMedias += progress;
          }
          mediaProgresso = somaMedias / progSubmissoes.length;
        }
      }

      // 6. Objetivos Ativos (retirar concluídos e expirados)
      int objetivosAtivos = 0;
      if (userId != null) {
        final objRes = await db.rawQuery('''
          SELECT data_final, data_conclusao
          FROM objetivos
          WHERE id_utilizador = ?
            AND deleted_objetivo = 0
        ''', [userId]);

        final now = DateTime.now();
        for (final row in objRes) {
          final dataConclusaoStr = row['data_conclusao']?.toString() ?? '';
          final concluido = dataConclusaoStr.isNotEmpty;

          if (!concluido) {
            final dataFinalStr = row['data_final']?.toString();
            final dataFinal = dataFinalStr != null ? DateTime.tryParse(dataFinalStr) : null;
            if (dataFinal != null) {
              final daysLeft = dataFinal.difference(now).inDays + 1;
              if (daysLeft > 0) {
                objetivosAtivos++;
              }
            }
          }
        }
      }


      // 7. Evolução de Badges e Pontos (Registo de Badges em cada momento)
      final List<Map<String, dynamic>> userRegistos = [];
      if (userId != null) {
        final registosRes = await db.rawQuery('''
          SELECT rb.data_obtencao, b.pontos_badge
          FROM registo_badges rb
          JOIN badges b ON rb.id_badge = b.id_badge
          WHERE rb.id_utilizador = ?
            AND rb.deleted_registo = 0
        ''', [userId]);
        userRegistos.addAll(registosRes);
      }

      final DateTime nowDt = DateTime.now();
      final currentYear = nowDt.year;
      final currentMonth = nowDt.month;

      final l10n = AppLocalizations.of(context);

      // --- Badges & Points Semana ---
      final DateTime monday = nowDt.subtract(Duration(days: nowDt.weekday - 1));
      final startOfWeek = DateTime(monday.year, monday.month, monday.day);
      final endOfWeek = startOfWeek.add(const Duration(days: 7));

      final List<double> badgesSemValues = List.filled(7, 0.0);
      final List<double> pointsSemValues = List.filled(7, 0.0);
      final List<String> semLabels = [
        l10n?.segundaAbbr ?? 'Seg',
        l10n?.tercaAbbr ?? 'Ter',
        l10n?.quartaAbbr ?? 'Qua',
        l10n?.quintaAbbr ?? 'Qui',
        l10n?.sextaAbbr ?? 'Sex',
        l10n?.sabadoAbbr ?? 'Sáb',
        l10n?.domingoAbbr ?? 'Dom',
      ];
      final List<String> semPointsLabels = [];
      for (int i = 0; i < 7; i++) {
        final day = startOfWeek.add(Duration(days: i));
        semPointsLabels.add('${day.day}/${day.month}');
      }

      // --- Badges & Points Mes ---
      final List<double> badgesMesValues = List.filled(4, 0.0);
      final List<double> pointsMesValues = List.filled(4, 0.0);
      final List<String> mesLabels = [
        '${l10n?.semanaLabel ?? 'Sem'} 1',
        '${l10n?.semanaLabel ?? 'Sem'} 2',
        '${l10n?.semanaLabel ?? 'Sem'} 3',
        '${l10n?.semanaLabel ?? 'Sem'} 4',
      ];

      // --- Badges Trim (Jan to Jun of current year) ---
      final List<double> badgesTrimValues = List.filled(6, 0.0);
      final List<String> badgesTrimLabels = [
        l10n?.janeiroAbbr ?? 'Jan',
        l10n?.fevereiroAbbr ?? 'Fev',
        l10n?.marcoAbbr ?? 'Mar',
        l10n?.abrilAbbr ?? 'Abr',
        l10n?.maioAbbr ?? 'Mai',
        l10n?.junhoAbbr ?? 'Jun',
      ];

      // --- Points Trim (last 3 months) ---
      final List<double> pointsTrimValues = List.filled(3, 0.0);
      final List<String> pointsTrimLabels = [];
      final List<int> last3Months = [];
      final List<int> last3Years = [];
      for (int i = 2; i >= 0; i--) {
        DateTime target = DateTime(nowDt.year, nowDt.month - i, 1);
        last3Months.add(target.month);
        last3Years.add(target.year);
        pointsTrimLabels.add(_obterAbbrMes(target.month, l10n));
      }

      // --- Badges & Points Ano (last 4 years) ---
      final List<double> badgesAnoValues = List.filled(4, 0.0);
      final List<double> pointsAnoValues = List.filled(4, 0.0);
      final List<String> anoLabels = [
        '${currentYear - 3}',
        '${currentYear - 2}',
        '${currentYear - 1}',
        '${currentYear}',
      ];

      for (final reg in userRegistos) {
        final dateStr = reg['data_obtencao']?.toString();
        if (dateStr == null) continue;
        final dt = DateTime.tryParse(dateStr);
        if (dt == null) continue;

        final pts = (reg['pontos_badge'] as num?)?.toDouble() ?? 0.0;

        if (dt.isAfter(startOfWeek.subtract(const Duration(seconds: 1))) && dt.isBefore(endOfWeek)) {
          final wday = dt.weekday;
          if (wday >= 1 && wday <= 7) {
            badgesSemValues[wday - 1] += 1.0;
            pointsSemValues[wday - 1] += pts;
          }
        }

        if (dt.year == currentYear && dt.month == currentMonth) {
          final day = dt.day;
          int weekIdx = 0;
          if (day <= 7) {
            weekIdx = 0;
          } else if (day <= 14) {
            weekIdx = 1;
          } else if (day <= 21) {
            weekIdx = 2;
          } else {
            weekIdx = 3;
          }
          badgesMesValues[weekIdx] += 1.0;
          pointsMesValues[weekIdx] += pts;
        }

        if (dt.year == currentYear && dt.month >= 1 && dt.month <= 6) {
          badgesTrimValues[dt.month - 1] += 1.0;
        }

        for (int i = 0; i < 3; i++) {
          if (dt.year == last3Years[i] && dt.month == last3Months[i]) {
            pointsTrimValues[i] += pts;
          }
        }

        final diffYear = currentYear - dt.year;
        if (diffYear >= 0 && diffYear <= 3) {
          badgesAnoValues[3 - diffYear] += 1.0;
          pointsAnoValues[3 - diffYear] += pts;
        }
      }

      final finalBadgeEvolutionData = {
        'Sem': List.generate(7, (i) => {'label': semLabels[i], 'value': badgesSemValues[i]}),
        'Mês': List.generate(4, (i) => {'label': mesLabels[i], 'value': badgesMesValues[i]}),
        'Trim': List.generate(6, (i) => {'label': badgesTrimLabels[i], 'value': badgesTrimValues[i]}),
        'Ano': List.generate(4, (i) => {'label': anoLabels[i], 'value': badgesAnoValues[i]}),
      };

      final finalPointsEvolutionData = {
        'Sem': List.generate(7, (i) => {'label': semPointsLabels[i], 'value': pointsSemValues[i]}),
        'Mês': List.generate(4, (i) => {'label': mesLabels[i], 'value': pointsMesValues[i]}),
        'Trim': List.generate(3, (i) => {'label': pointsTrimLabels[i], 'value': pointsTrimValues[i]}),
        'Ano': List.generate(4, (i) => {'label': anoLabels[i], 'value': pointsAnoValues[i]}),
      };

      if (mounted) {
        setState(() {
          _totalBadgesKpiValue = totalBadges;
          _lugarGeralKpiValue = lugarGeral;
          _mediaProgressoKpiValue = mediaProgresso;
          _objetivosAtivosKpiValue = objetivosAtivos;
          _listaClassificacao = todosUsers;
          _distribuicaoBadges = distBadges;
          _distribuicaoNiveis = distNiveis;
          _badgeEvolutionData = finalBadgeEvolutionData;
          _pointsEvolutionData = finalPointsEvolutionData;
          _isLoading = false;
        });
      }
    } catch (e, stack) {
      print('❌ [EstatisticasScreen] Error loading data: $e');
      print(stack);
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        backgroundColor: AppCores.branco,
        appBar: AppBar(
          backgroundColor: AppCores.branco,
          surfaceTintColor: Colors.transparent,
          elevation: 0,
          centerTitle: false,
          titleSpacing: AppTamanhos.colocacao_titulo,
          title: Text(
            AppLocalizations.of(context)?.estatisticasTitulo ?? 'Estatísticas',
            style: const TextStyle(
              color: AppCores.fontes,
              fontSize: AppTamanhos.titulo,
            ),
          ),
          actions: const [
            TopBarActions(showDocumentIcon: true),
          ],
        ),
        body: const Center(
          child: CircularProgressIndicator(
            color: AppCores.azulFundo,
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: AppCores.branco,
      appBar: AppBar(
        backgroundColor: AppCores.branco,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        centerTitle: false,
        titleSpacing: AppTamanhos.colocacao_titulo,
        title: Text(
          AppLocalizations.of(context)?.estatisticasTitulo ?? 'Estatísticas',
          style: const TextStyle(
            color: AppCores.fontes,
            fontSize: AppTamanhos.titulo,
          ),
        ),
        actions: const [
          TopBarActions(showDocumentIcon: true),
        ],
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildKpiGrid(),
              const SizedBox(height: 24),
              _buildDistributionCard(),
              const SizedBox(height: 24),
              _buildClassificacaoGeralCard(),
              const SizedBox(height: 24),
              _buildBadgesByLevelCard(),
              const SizedBox(height: 24),
              _buildBadgeEvolutionCard(),
              const SizedBox(height: 24),
              _buildPointsEvolutionCard(),
            ],
          ),
        ),
      ),
    );
  }

  // ── KPI ─────────────────────────────────────────────────────────────────
  Widget _buildKpiGrid() {
    final l10n = AppLocalizations.of(context);
    final kpiCards = [
      {
        'icon': UIcons.boldRounded.badge,
        'iconColor': AppCores.azulFundo,
        'value': _totalBadgesKpiValue.toString(),
        'label': l10n?.totalBadgesKpi ?? 'Total de Badges',
      },
      {
        'icon': UIcons.boldRounded.trophy,
        'iconColor': const Color(0xFF5EA500),
        'value': _lugarGeralKpiValue,
        'label': l10n?.lugarGeralKpi ?? 'Lugar geral',
      },
      {
        'icon': UIcons.boldRounded.chart_histogram,
        'iconColor': const Color(0xFFE17100),
        'value': '${(_mediaProgressoKpiValue * 100).toStringAsFixed(0)}%',
        'label': l10n?.mediaProgressoKpi ?? 'Média de Progresso',
      },
      {
        'icon': UIcons.boldRounded.target,
        'iconColor': const Color(0xFFAE012F),
        'value': _objetivosAtivosKpiValue.toString(),
        'label': l10n?.objetivosAtivosKpi ?? 'Objetivos Ativos',
      },
    ];

    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: _buildMetricCard(
                icon: kpiCards[0]['icon'] as IconData,
                iconColor: kpiCards[0]['iconColor'] as Color,
                value: kpiCards[0]['value'] as String,
                label: kpiCards[0]['label'] as String,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildMetricCard(
                icon: kpiCards[1]['icon'] as IconData,
                iconColor: kpiCards[1]['iconColor'] as Color,
                value: kpiCards[1]['value'] as String,
                label: kpiCards[1]['label'] as String,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _buildMetricCard(
                icon: kpiCards[2]['icon'] as IconData,
                iconColor: kpiCards[2]['iconColor'] as Color,
                value: kpiCards[2]['value'] as String,
                label: kpiCards[2]['label'] as String,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildMetricCard(
                icon: kpiCards[3]['icon'] as IconData,
                iconColor: kpiCards[3]['iconColor'] as Color,
                value: kpiCards[3]['value'] as String,
                label: kpiCards[3]['label'] as String,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildMetricCard({
    required IconData icon,
    required Color iconColor,
    required String value,
    required String label,
  }) {
    return Container(
      padding: const EdgeInsets.all(16.0),
      decoration: BoxDecoration(
        color: AppCores.branco,
        borderRadius: BorderRadius.circular(AppBorders.padrao),
        border: Border.all(color: AppCores.outline),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8.0),
            decoration: BoxDecoration(
              color: iconColor.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(
              icon,
              color: iconColor,
              size: 20.0,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            value,
            style: const TextStyle(
              color: AppCores.fontes,
              fontSize: 24.0,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: const TextStyle(
              color: Color(0xFF767676),
              fontSize: 12.0,
            ),
          ),
        ],
      ),
    );
  }

  // ── DISTRIBUIÇÃO DE BADGES ──────────────────────────────────────────────
  Widget _buildDistributionCard() {
    final total = _distribuicaoBadges.fold<int>(
      0,
      (sum, item) => sum + (item['total_badges'] as int),
    );

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20.0),
      decoration: BoxDecoration(
        color: AppCores.branco,
        borderRadius: BorderRadius.circular(AppBorders.padrao),
        border: Border.all(color: AppCores.outline),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                AppLocalizations.of(context)?.distribuicaoBadges ?? 'Distribuição de Badges',
                style: const TextStyle(
                  color: AppCores.fontes,
                  fontSize: 16.0,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              SizedBox(
                width: 130,
                height: 130,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    PieChart(
                      PieChartData(
                        sectionsSpace: 2,
                        centerSpaceRadius: 36,
                        sections: _distribuicaoBadges.map((item) {
                          final value = item['total_badges'] as int;
                          return PieChartSectionData(
                            color: Color(item['cor'] as int),
                            value: value.toDouble(),
                            title: '',
                            radius: 20,
                            badgeWidget: null,
                            titlePositionPercentageOffset: 0,
                          );
                        }).toList(),
                      ),
                    ),
                    Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          '$total',
                          style: const TextStyle(
                            color: AppCores.fontes,
                            fontSize: 18.0,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const Text(
                          'total',
                          style: TextStyle(
                            color: Color(0xFF8FA3B8),
                            fontSize: 10.0,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 18),
              Flexible(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: _distribuicaoBadges.map((item) {
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 8.0),
                      child: _buildLegendItem(
                        color: Color(item['cor'] as int),
                        label: item['Nome_Area'] as String,
                        value: item['total_badges'].toString(),
                      ),
                    );
                  }).toList(),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildLegendItem({
    required Color color,
    required String label,
    required String value,
  }) {
    return Row(
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: 6),
        Expanded(
          child: Text(
            label,
            style: const TextStyle(
              color: AppCores.fontes,
              fontSize: 12.0,
              fontWeight: FontWeight.w500,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
        const SizedBox(width: 8),
        Text(
          value,
          style: const TextStyle(
            color: AppCores.fontes,
            fontSize: 12.0,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }

  // ── CLASSIFICAÇÃO GERAL ─────────────────────────────────────────────────
  Widget _buildClassificacaoGeralCard() {
    final listaOrdenada = _getListaOrdenadaPreview();

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20.0),
      decoration: BoxDecoration(
        color: AppCores.branco,
        borderRadius: BorderRadius.circular(AppBorders.padrao),
        border: Border.all(color: AppCores.outline),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                AppLocalizations.of(context)?.classificacaoGeralTitulo ?? 'Classificação Geral',
                style: const TextStyle(
                  color: AppCores.fontes,
                  fontSize: 16.0,
                  fontWeight: FontWeight.bold,
                ),
              ),
              GestureDetector(
                onTap: () => _openClassificacaoModal(context),
                child: Icon(
                  UIcons.boldRounded.expand,
                  color: AppCores.fontes,
                  size: 18.0,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Column(
            children: listaOrdenada.take(5).map((item) {
              return Padding(
                padding: const EdgeInsets.only(bottom: 10.0),
                child: _buildClassificacaoRow(item: item, compact: true),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  List<Map<String, dynamic>> _getListaOrdenadaPreview() {
    final copia = List<Map<String, dynamic>>.from(_listaClassificacao);
    copia.sort((a, b) => (b['pontos_sempre'] as int).compareTo(a['pontos_sempre'] as int));

    return copia.asMap().entries.map((entry) {
      final idx = entry.key;
      final item = entry.value;
      final pos = idx + 1;
      return {
        ...item,
        'pos': pos,
        'pontos': (item['pontos_sempre'] as int).toString(),
        'cor': pos == 1
            ? const Color(0xFFFFD700)
            : pos == 2
                ? const Color(0xFFC0C0C0)
                : pos == 3
                    ? const Color(0xFFCD7F32)
                    : null,
        'classe': pos == 1
            ? 'ouro'
            : pos == 2
                ? 'prata'
                : pos == 3
                    ? 'bronze'
                    : null,
      };
    }).toList();
  }

  Widget _buildClassificacaoRow({
    required Map<String, dynamic> item,
    required bool compact,
  }) {
    final pos = item['pos'] as int;
    final cor = item['cor'] as Color?;
    final img = item['img'] as String?;

    return Row(
      children: [
        _buildRankIndicator(pos: pos, cor: cor, compact: compact),
        const SizedBox(width: 12),
        Container(
          width: compact ? 32 : 40,
          height: compact ? 32 : 40,
          decoration: BoxDecoration(
            color: AppCores.outline.withValues(alpha: 0.3),
            shape: BoxShape.circle,
          ),
          child: ClipOval(
            child: (img != null && img.isNotEmpty)
                ? Image.network(
                    img,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) {
                      return Image.asset(
                        'assets/images/default_pint.jpg',
                        fit: BoxFit.cover,
                      );
                    },
                    loadingBuilder: (context, child, loadingProgress) {
                      if (loadingProgress == null) return child;
                      return Center(
                        child: SizedBox(
                          width: compact ? 12 : 16,
                          height: compact ? 12 : 16,
                          child: const CircularProgressIndicator(
                            strokeWidth: 1.5,
                            color: AppCores.azulFundo,
                          ),
                        ),
                      );
                    },
                  )
                : Image.asset(
                    'assets/images/default_pint.jpg',
                    fit: BoxFit.cover,
                  ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                item['nome'] as String,
                style: TextStyle(
                  color: AppCores.fontes,
                  fontSize: compact ? 13.0 : 14.0,
                  fontWeight: FontWeight.w600,
                ),
                overflow: TextOverflow.ellipsis,
              ),
              Text(
                item['area'] as String,
                style: TextStyle(
                  color: const Color(0xFF8796A2),
                  fontSize: compact ? 11.0 : 12.0,
                ),
              ),
            ],
          ),
        ),
        Text(
          '${item['pontos']} pts',
          style: const TextStyle(
            color: AppCores.azulFundo,
            fontSize: 13.0,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }

  Widget _buildRankIndicator({
    required int pos,
    required Color? cor,
    required bool compact,
  }) {
    if (pos <= 3) {
      return Icon(
        UIcons.boldRounded.badge,
        color: cor,
        size: compact ? 20 : 26,
      );
    }

    return Container(
      width: compact ? 22 : 28,
      height: compact ? 22 : 28,
      decoration: BoxDecoration(
        color: AppCores.outline.withValues(alpha: 0.25),
        shape: BoxShape.circle,
      ),
      child: Center(
        child: Text(
          '$pos',
          style: TextStyle(
            color: AppCores.fontes,
            fontSize: compact ? 11 : 12,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }

  void _openClassificacaoModal(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => ClassificacaoModal(dados: _listaClassificacao),
    );
  }

  // ── BADGES POR NÍVEL ────────────────────────────────────────────────────
  Widget _buildBadgesByLevelCard() {
    final total = _distribuicaoNiveis.fold<int>(
      0,
      (sum, item) => sum + (item['value'] as int),
    );
    final maxValue = _distribuicaoNiveis.isEmpty
        ? 0
        : _distribuicaoNiveis
            .map((e) => e['value'] as int)
            .reduce((a, b) => a > b ? a : b);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20.0),
      decoration: BoxDecoration(
        color: AppCores.branco,
        borderRadius: BorderRadius.circular(AppBorders.padrao),
        border: Border.all(color: AppCores.outline),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  AppLocalizations.of(context)?.badgesPorNivel ?? 'Badges Conquistados (por nível)',
                  style: const TextStyle(
                    color: AppCores.fontes,
                    fontSize: 15.0,
                    fontWeight: FontWeight.bold,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: 8),
              Text(
                '$total',
                style: const TextStyle(
                  color: AppCores.fontes,
                  fontSize: 16.0,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Column(
            children: _distribuicaoNiveis.map((level) {
              final progress = maxValue > 0 ? (level['value'] as int) / maxValue : 0.0;
              final color = Color(level['color'] as int);

              return Padding(
                padding: const EdgeInsets.only(bottom: 14.0),
                child: Row(
                  children: [
                    SizedBox(
                      width: 90,
                      child: Text(
                        level['label'] as String,
                        style: const TextStyle(
                          color: AppCores.fontes,
                          fontSize: 12.0,
                          fontWeight: FontWeight.w600,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Container(
                        height: 10,
                        decoration: BoxDecoration(
                          color: const Color(0xFFF0F2F6),
                          borderRadius: BorderRadius.circular(999),
                        ),
                        child: FractionallySizedBox(
                          alignment: Alignment.centerLeft,
                          widthFactor: progress,
                          child: Container(
                            decoration: BoxDecoration(
                              color: color,
                              borderRadius: BorderRadius.circular(999),
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    SizedBox(
                      width: 32,
                      child: Text(
                        '${level['value']}',
                        style: TextStyle(
                          color: color,
                          fontSize: 13.0,
                          fontWeight: FontWeight.w800,
                        ),
                        textAlign: TextAlign.right,
                      ),
                    ),
                  ],
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  // ── EVOLUÇÃO DE BADGES ──────────────────────────────────────────────────
  Widget _buildBadgeEvolutionCard() {
    final currentData = _badgeEvolutionData[_badgesPeriod] ?? [];
    final double maxY;
    if (currentData.isEmpty) {
      maxY = 10.0;
    } else {
      final maxVal = currentData.map((e) => (e['value'] as num).toDouble()).reduce((a, b) => a > b ? a : b);
      maxY = maxVal <= 0 ? 10.0 : maxVal * 1.2;
    }
    final spots = currentData.asMap().entries.map((entry) {
      return FlSpot(entry.key.toDouble(), (entry.value['value'] as num).toDouble());
    }).toList();

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20.0),
      decoration: BoxDecoration(
        color: AppCores.branco,
        borderRadius: BorderRadius.circular(AppBorders.padrao),
        border: Border.all(color: AppCores.outline),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Flexible(
                child: Text(
                  AppLocalizations.of(context)?.evolucaoBadges ?? 'Evolução de Badges',
                  style: const TextStyle(
                    color: AppCores.fontes,
                    fontSize: 15.0,
                    fontWeight: FontWeight.bold,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: 8),
              _buildPeriodPills(
                options: const ['Sem', 'Mês', 'Trim', 'Ano'],
                selected: _badgesPeriod,
                onSelected: (value) => setState(() => _badgesPeriod = value),
              ),
            ],
          ),
          const SizedBox(height: 24),
          SizedBox(
            height: 200,
            child: LineChart(
              LineChartData(
                minY: 0,
                maxY: maxY,
                gridData: FlGridData(
                  show: true,
                  drawVerticalLine: false,
                  getDrawingHorizontalLine: (value) {
                    return FlLine(
                      color: AppCores.outline.withValues(alpha: 0.5),
                      strokeWidth: 1,
                    );
                  },
                ),
                borderData: FlBorderData(show: false),
                titlesData: FlTitlesData(
                  leftTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  rightTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  topTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      interval: 1,
                      getTitlesWidget: (value, meta) {
                        final index = value.toInt();
                        if (index < 0 || index >= currentData.length) {
                          return const SizedBox.shrink();
                        }
                        return Padding(
                          padding: const EdgeInsets.only(top: 8.0),
                          child: Text(
                            currentData[index]['label'],
                            style: const TextStyle(
                              color: Color(0xFF8796A2),
                              fontSize: 11.0,
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ),
                lineBarsData: [
                  LineChartBarData(
                    spots: spots,
                    isCurved: true,
                    curveSmoothness: 0.35,
                    preventCurveOverShooting: true,
                    color: AppCores.azulFundo,
                    barWidth: 4,
                    isStrokeCapRound: true,
                    dotData: FlDotData(
                      show: true,
                      getDotPainter: (spot, percent, bar, index) {
                        return FlDotCirclePainter(
                          radius: 5,
                          color: AppCores.branco,
                          strokeWidth: 3,
                          strokeColor: AppCores.azulFundo,
                        );
                      },
                    ),
                    belowBarData: BarAreaData(
                      show: true,
                      gradient: LinearGradient(
                        colors: [
                          AppCores.azulFundo.withValues(alpha: 0.25),
                          AppCores.azulFundo.withValues(alpha: 0.05),
                          AppCores.azulFundo.withValues(alpha: 0.0),
                        ],
                        stops: const [0.0, 0.5, 1.0],
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── EVOLUÇÃO DE PONTOS ──────────────────────────────────────────────────
  Widget _buildPointsEvolutionCard() {
    final currentData = _pointsEvolutionData[_pointsPeriod] ?? [];
    final double maxY;
    if (currentData.isEmpty) {
      maxY = 100.0;
    } else {
      final maxVal = currentData.map((e) => (e['value'] as num).toDouble()).reduce((a, b) => a > b ? a : b);
      maxY = maxVal <= 0 ? 100.0 : maxVal * 1.25;
    }
    const Color barColor = Color(0xFF39639C);
    const double chartHeight = 220;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20.0),
      decoration: BoxDecoration(
        color: AppCores.branco,
        borderRadius: BorderRadius.circular(AppBorders.padrao),
        border: Border.all(color: AppCores.outline),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Flexible(
                child: Text(
                  AppLocalizations.of(context)?.evolucaoPontos ?? 'Evolução de Pontos',
                  style: const TextStyle(
                    color: AppCores.fontes,
                    fontSize: 15.0,
                    fontWeight: FontWeight.bold,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: 8),
              _buildPeriodPills(
                options: const ['Sem', 'Mês', 'Trim', 'Ano'],
                selected: _pointsPeriod,
                onSelected: (value) => setState(() => _pointsPeriod = value),
              ),
            ],
          ),
          const SizedBox(height: 24),
          SizedBox(
            height: chartHeight,
            child: Stack(
              children: [
                BarChart(
                  BarChartData(
                    alignment: BarChartAlignment.spaceAround,
                    maxY: maxY,
                    minY: 0,
                    gridData: FlGridData(
                      show: true,
                      drawVerticalLine: false,
                      getDrawingHorizontalLine: (value) {
                        return const FlLine(
                          color: Color(0xFFF0F0F0),
                          strokeWidth: 1,
                        );
                      },
                    ),
                    borderData: FlBorderData(show: false),
                    titlesData: FlTitlesData(
                      leftTitles: const AxisTitles(
                        sideTitles: SideTitles(showTitles: false),
                      ),
                      rightTitles: const AxisTitles(
                        sideTitles: SideTitles(showTitles: false),
                      ),
                      topTitles: const AxisTitles(
                        sideTitles: SideTitles(showTitles: false),
                      ),
                      bottomTitles: AxisTitles(
                        sideTitles: SideTitles(
                          showTitles: true,
                          getTitlesWidget: (value, meta) {
                            final index = value.toInt();
                            if (index < 0 || index >= currentData.length) {
                              return const SizedBox.shrink();
                            }
                            return Padding(
                              padding: const EdgeInsets.only(top: 8.0),
                              child: Text(
                                currentData[index]['label'],
                                style: const TextStyle(
                                  color: Color(0xFF8796A2),
                                  fontSize: 10.0,
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                    ),
                    barGroups: currentData.asMap().entries.map((entry) {
                      final index = entry.key;
                      final point = entry.value;
                      return BarChartGroupData(
                        x: index,
                        barRods: [
                          BarChartRodData(
                            toY: point['value'],
                            color: barColor,
                            width: currentData.length > 6 ? 20 : 34,
                            borderRadius: const BorderRadius.vertical(
                              top: Radius.circular(6),
                            ),
                          ),
                        ],
                      );
                    }).toList(),
                  ),
                ),
                Positioned(
                  top: 0,
                  left: 0,
                  right: 0,
                  bottom: 28,
                  child: Row(
                    children: currentData.map((point) {
                      final value = point['value'] as double;
                      return Expanded(
                        child: LayoutBuilder(
                          builder: (context, constraints) {
                            final availableHeight = constraints.maxHeight;
                            final barHeight = (value / maxY) * availableHeight;
                            return Align(
                              alignment: Alignment.bottomCenter,
                              child: Padding(
                                padding: EdgeInsets.only(bottom: barHeight + 2),
                                child: value > 0
                                    ? Text(
                                        value.toInt().toString(),
                                        style: const TextStyle(
                                          color: Color(0xFF8796A2),
                                          fontSize: 9.5,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      )
                                    : const SizedBox.shrink(),
                              ),
                            );
                          },
                        ),
                      );
                    }).toList(),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _obterAbbrMes(int month, AppLocalizations? l10n) {
    switch (month) {
      case 1: return l10n?.janeiroAbbr ?? 'Jan';
      case 2: return l10n?.fevereiroAbbr ?? 'Fev';
      case 3: return l10n?.marcoAbbr ?? 'Mar';
      case 4: return l10n?.abrilAbbr ?? 'Abr';
      case 5: return l10n?.maioAbbr ?? 'Mai';
      case 6: return l10n?.junhoAbbr ?? 'Jun';
      case 7: return 'Jul';
      case 8: return 'Ago';
      case 9: return 'Set';
      case 10: return 'Out';
      case 11: return 'Nov';
      case 12: return 'Dez';
      default: return '';
    }
  }

  String _getPeriodoLabel(String option) {
    final l10n = AppLocalizations.of(context);
    switch (option) {
      case 'Sem':
        return l10n?.periodoSemanaAbbr ?? 'Sem';
      case 'Mês':
        return l10n?.periodoMesAbbr ?? 'Mês';
      case 'Trim':
        return l10n?.periodoTrimestreAbbr ?? 'Trim';
      case 'Ano':
        return l10n?.periodoAnoAbbr ?? 'Ano';
      default:
        return option;
    }
  }

  Widget _buildPeriodPills({
    required List<String> options,
    required String selected,
    required ValueChanged<String> onSelected,
  }) {
    return Container(
      padding: const EdgeInsets.all(3.0),
      decoration: BoxDecoration(
        color: const Color(0xFFF0F2F6),
        borderRadius: BorderRadius.circular(20.0),
        border: Border.all(color: AppCores.outline),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: options.map((option) {
          final isSelected = option == selected;
          return GestureDetector(
            onTap: () => onSelected(option),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 5.0),
              decoration: BoxDecoration(
                color: isSelected ? AppCores.azulFundo : Colors.transparent,
                borderRadius: BorderRadius.circular(14.0),
                boxShadow: isSelected
                    ? [
                        BoxShadow(
                          color: AppCores.azulFundo.withValues(alpha: 0.25),
                          blurRadius: 4,
                          offset: const Offset(0, 2),
                        ),
                      ]
                    : null,
              ),
              child: Text(
                _getPeriodoLabel(option),
                style: TextStyle(
                  color: isSelected ? AppCores.branco : AppCores.fontes,
                  fontSize: 9.5,
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }


}

// ═══════════════════════════════════════════════════════════════════════════
// MODAL DE CLASSIFICAÇÃO GERAL
// ═══════════════════════════════════════════════════════════════════════════
class ClassificacaoModal extends StatefulWidget {
  final List<Map<String, dynamic>> dados;

  const ClassificacaoModal({super.key, required this.dados});

  @override
  State<ClassificacaoModal> createState() => _ClassificacaoModalState();
}

class _ClassificacaoModalState extends State<ClassificacaoModal> {
  String? _filtro;
  String? _filtroValor;
  String _periodo = 'sempre';
  bool _subMenuAberto = false;

  final List<String> _filtroOpcoes = const ['area', 'service_line'];
  final List<String> _periodoOpcoes = const ['semana', 'mes', 'ano', 'sempre'];

  List<Map<String, dynamic>> get _listaOrdenada {
    List<Map<String, dynamic>> dados = List<Map<String, dynamic>>.from(widget.dados);

    if (_filtro != null && _filtroValor != null) {
      dados = dados.where((u) => u[_filtro!] == _filtroValor).toList();
    }

    final chave = 'pontos_$_periodo';
    dados.sort((a, b) => ((b[chave] as int?) ?? 0).compareTo((a[chave] as int?) ?? 0));

    return dados.asMap().entries.map((entry) {
      final idx = entry.key;
      final item = entry.value;
      final pos = idx + 1;
      final pontos = (item[chave] as int?) ?? 0;

      return {
        ...item,
        'pos': pos,
        'pontos': pontos.toString(),
        'cor': pos == 1
            ? const Color(0xFFFFD700)
            : pos == 2
                ? const Color(0xFFC0C0C0)
                : pos == 3
                    ? const Color(0xFFCD7F32)
                    : null,
        'classe': pos == 1
            ? 'ouro'
            : pos == 2
                ? 'prata'
            : pos == 3
                ? 'bronze'
                : null,
      };
    }).toList();
  }

  List<String> _getValoresUnicos(String categoria) {
    return widget.dados
        .map((u) {
          final val = u[categoria];
          if (val == null) return null;
          return val.toString();
        })
        .where((v) => v != null && v!.isNotEmpty)
        .cast<String>()
        .toSet()
        .toList();
  }

  String _labelFiltro(String chave) {
    final l10n = AppLocalizations.of(context);
    switch (chave) {
      case 'area':
        return l10n?.filtroArea ?? 'Área';
      case 'service_line':
        return l10n?.filtroServiceLine ?? 'Service Line';
      case 'funcao':
        return l10n?.filtroFuncao ?? 'Função';
      default:
        return chave;
    }
  }

  String _labelPeriodo(String chave) {
    final l10n = AppLocalizations.of(context);
    switch (chave) {
      case 'semana':
        return l10n?.periodoSemana ?? 'Semana';
      case 'mes':
        return l10n?.periodoMes ?? 'Mês';
      case 'ano':
        return l10n?.periodoAno ?? 'Ano';
      case 'sempre':
        return l10n?.periodoSempre ?? 'Sempre';
      default:
        return chave;
    }
  }

  @override
  Widget build(BuildContext context) {
    final lista = _listaOrdenada;
    final podio = <Map<String, dynamic>>[];
    if (lista.length > 1) podio.add(lista[1]);
    if (lista.isNotEmpty) podio.add(lista[0]);
    if (lista.length > 2) podio.add(lista[2]);
    final restantes = lista.length > 3 ? lista.sublist(3) : <Map<String, dynamic>>[];

    return Container(
      height: MediaQuery.of(context).size.height * 0.9,
      decoration: const BoxDecoration(
        color: AppCores.branco,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24.0)),
      ),
      child: Column(
        children: [
          // Handle
          Padding(
            padding: const EdgeInsets.only(top: 12.0, bottom: 8.0),
            child: Container(
              width: 40,
              height: 5,
              decoration: BoxDecoration(
                color: AppCores.outline.withValues(alpha: 0.6),
                borderRadius: BorderRadius.circular(999),
              ),
            ),
          ),
          // Header
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  AppLocalizations.of(context)?.classificacaoGeralTitulo ?? 'Classificação Geral',
                  style: const TextStyle(
                    color: AppCores.fontes,
                    fontSize: 18.0,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                GestureDetector(
                  onTap: () => Navigator.of(context).pop(),
                  child: Container(
                    width: 34,
                    height: 34,
                    decoration: BoxDecoration(
                      color: const Color(0xFFF0F4F8),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.close,
                      color: Color(0xFF666666),
                      size: 18,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          // Filtros
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20.0),
            child: Row(
              children: [
                Expanded(
                  child: _buildFilterButton(
                    label: _filtro != null && _filtroValor != null
                        ? '${_labelFiltro(_filtro!)}: $_filtroValor'
                        : (AppLocalizations.of(context)?.filtrar ?? 'Filtrar'),
                    isOpen: _subMenuAberto,
                    onTap: () => setState(() => _subMenuAberto = !_subMenuAberto),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildFilterButton(
                    label: _labelPeriodo(_periodo),
                    isOpen: false,
                    onTap: () => _showPeriodoMenu(context),
                  ),
                ),
              ],
            ),
          ),
          if (_subMenuAberto) ...[
            const SizedBox(height: 12),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20.0),
              child: _buildSubMenuFiltro(),
            ),
          ],
          const SizedBox(height: 20),
          // Podio
          if (lista.isNotEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20.0),
              child: _buildPodio(podio),
            ),
          if (lista.isEmpty)
            Padding(
              padding: const EdgeInsets.all(24.0),
              child: Text(
                AppLocalizations.of(context)?.nenhumUtilizadorEncontrado ?? 'Nenhum utilizador encontrado para este filtro.',
                style: const TextStyle(color: Color(0xFF8796A2), fontSize: 14.0),
              ),
            ),
          const SizedBox(height: 48),
          // Lista
          Expanded(
            child: ListView.separated(
              padding: const EdgeInsets.symmetric(horizontal: 20.0),
              itemCount: restantes.length,
              separatorBuilder: (context, index) => const SizedBox(height: 8),
              itemBuilder: (context, index) {
                final item = restantes[index];
                return _buildClassificacaoModalRow(item);
              },
            ),
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }

  Widget _buildFilterButton({
    required String label,
    required bool isOpen,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14.0, vertical: 10.0),
        decoration: BoxDecoration(
          color: isOpen ? const Color(0xFFF0F4F8) : AppCores.branco,
          borderRadius: BorderRadius.circular(12.0),
          border: Border.all(
            color: isOpen ? AppCores.azulFundo : AppCores.outline,
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Flexible(
              child: Text(
                label,
                style: TextStyle(
                  color: AppCores.fontes,
                  fontSize: 13.0,
                  fontWeight: FontWeight.w500,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            const SizedBox(width: 6),
            Icon(
              isOpen ? Icons.keyboard_arrow_up : Icons.keyboard_arrow_down,
              color: AppCores.fontes,
              size: 16,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSubMenuFiltro() {
    if (_filtro == null) {
      return Container(
        padding: const EdgeInsets.all(12.0),
        decoration: BoxDecoration(
          color: AppCores.branco,
          borderRadius: BorderRadius.circular(14.0),
          border: Border.all(color: AppCores.outline),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.06),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.only(left: 8.0, bottom: 8.0),
              child: Text(
                AppLocalizations.of(context)?.filtrarPor ?? 'Filtrar por',
                style: const TextStyle(
                  color: AppCores.fontes,
                  fontSize: 12.0,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            _buildSubMenuItem(
              label: AppLocalizations.of(context)?.todos ?? 'Todos',
              selected: _filtro == null,
              onTap: () => setState(() {
                _filtro = null;
                _filtroValor = null;
                _subMenuAberto = false;
              }),
            ),
            ..._filtroOpcoes.map((op) {
              return _buildSubMenuItem(
                label: _labelFiltro(op),
                selected: _filtro == op,
                onTap: () => setState(() => _filtro = op),
              );
            }),
          ],
        ),
      );
    }

    final valores = _getValoresUnicos(_filtro!);
    return Container(
      padding: const EdgeInsets.all(12.0),
      decoration: BoxDecoration(
        color: AppCores.branco,
        borderRadius: BorderRadius.circular(14.0),
        border: Border.all(color: AppCores.outline),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          GestureDetector(
            onTap: () => setState(() => _filtro = null),
            child: Padding(
              padding: const EdgeInsets.only(left: 8.0, bottom: 8.0),
              child: Row(
                children: [
                  const Icon(Icons.keyboard_arrow_left, size: 18, color: AppCores.fontes),
                  const SizedBox(width: 4),
                  Text(
                    _labelFiltro(_filtro!),
                    style: const TextStyle(
                      color: AppCores.fontes,
                      fontSize: 12.0,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ),
          ConstrainedBox(
            constraints: const BoxConstraints(maxHeight: 220),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: valores.map((val) {
                  return _buildSubMenuItem(
                    label: val,
                    selected: _filtroValor == val,
                    onTap: () => setState(() {
                      _filtroValor = val;
                      _subMenuAberto = false;
                    }),
                  );
                }).toList(),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSubMenuItem({
    required String label,
    required bool selected,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 10.0, vertical: 10.0),
        decoration: BoxDecoration(
          color: selected ? const Color(0xFFEEF4FF) : Colors.transparent,
          borderRadius: BorderRadius.circular(10.0),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: selected ? AppCores.azulFundo : AppCores.fontes,
            fontSize: 13.0,
            fontWeight: selected ? FontWeight.w600 : FontWeight.w500,
          ),
        ),
      ),
    );
  }

  void _showPeriodoMenu(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return Container(
          padding: const EdgeInsets.all(20.0),
          decoration: const BoxDecoration(
            color: AppCores.branco,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24.0)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                AppLocalizations.of(context)?.ordenarPor ?? 'Rankear por',
                style: const TextStyle(
                  color: AppCores.fontes,
                  fontSize: 16.0,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),
              ..._periodoOpcoes.map((op) {
                final selected = _periodo == op;
                return GestureDetector(
                  onTap: () {
                    setState(() => _periodo = op);
                    Navigator.of(context).pop();
                  },
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(vertical: 14.0, horizontal: 12.0),
                    margin: const EdgeInsets.only(bottom: 8.0),
                    decoration: BoxDecoration(
                      color: selected ? const Color(0xFFEEF4FF) : Colors.transparent,
                      borderRadius: BorderRadius.circular(12.0),
                    ),
                    child: Text(
                      _labelPeriodo(op),
                      style: TextStyle(
                        color: selected ? AppCores.azulFundo : AppCores.fontes,
                        fontSize: 14.0,
                        fontWeight: selected ? FontWeight.w600 : FontWeight.w500,
                      ),
                    ),
                  ),
                );
              }),
            ],
          ),
        );
      },
    );
  }

  Widget _buildPodio(List<Map<String, dynamic>> podio) {
    return SizedBox(
      height: 200,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          if (podio.isNotEmpty)
            Expanded(
              child: _buildPodioCard(
                item: podio[0],
                scale: 0.9,
                translateY: 16,
                corBorda: podio[0]['classe'] == 'prata'
                    ? const Color(0xFFC0C0C0)
                    : const Color(0xFFCD7F32),
                corFundo: podio[0]['classe'] == 'prata'
                    ? const Color(0xFFF8F8F8)
                    : const Color(0xFFFDF6EC),
              ),
            ),
          if (podio.length > 1)
            Expanded(
              child: _buildPodioCard(
                item: podio[1],
                scale: 1.05,
                translateY: -12,
                corBorda: const Color(0xFFFFD700),
                corFundo: const Color(0xFFFFFBEA),
                destacado: true,
              ),
            ),
          if (podio.length > 2)
            Expanded(
              child: _buildPodioCard(
                item: podio[2],
                scale: 0.85,
                translateY: 28,
                corBorda: const Color(0xFFCD7F32),
                corFundo: const Color(0xFFFDF6EC),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildPodioCard({
    required Map<String, dynamic> item,
    required double scale,
    required double translateY,
    required Color corBorda,
    required Color corFundo,
    bool destacado = false,
  }) {
    final img = item['img'] as String?;
    return Transform.translate(
      offset: Offset(0, translateY),
      child: Transform.scale(
        scale: scale,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 10.0, horizontal: 8.0),
          decoration: BoxDecoration(
            color: corFundo,
            borderRadius: BorderRadius.circular(16.0),
            border: Border.all(color: corBorda, width: 1.5),
            boxShadow: destacado
                ? [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.08),
                      blurRadius: 14,
                      offset: const Offset(0, 6),
                    ),
                  ]
                : null,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                UIcons.boldRounded.badge,
                color: corBorda,
                size: destacado ? 30 : 22,
              ),
              const SizedBox(height: 6),
              Container(
                width: destacado ? 48 : 36,
                height: destacado ? 48 : 36,
                decoration: BoxDecoration(
                  color: AppCores.outline.withValues(alpha: 0.3),
                  shape: BoxShape.circle,
                ),
                child: ClipOval(
                  child: (img != null && img.isNotEmpty)
                      ? Image.network(
                          img,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) {
                            return Image.asset(
                              'assets/images/default_pint.jpg',
                              fit: BoxFit.cover,
                            );
                          },
                          loadingBuilder: (context, child, loadingProgress) {
                            if (loadingProgress == null) return child;
                            return Center(
                              child: SizedBox(
                                width: destacado ? 16 : 12,
                                height: destacado ? 16 : 12,
                                child: const CircularProgressIndicator(
                                  strokeWidth: 1.5,
                                  color: AppCores.azulFundo,
                                ),
                              ),
                            );
                          },
                        )
                      : Image.asset(
                          'assets/images/default_pint.jpg',
                          fit: BoxFit.cover,
                        ),
                ),
              ),
              const SizedBox(height: 5),
              Text(
                item['nome'] as String,
                style: TextStyle(
                  color: AppCores.fontes,
                  fontSize: destacado ? 13 : 11,
                  fontWeight: FontWeight.w600,
                ),
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
              ),
              Text(
                item['area'] as String,
                style: TextStyle(
                  color: const Color(0xFF8796A2),
                  fontSize: destacado ? 11 : 9.5,
                ),
              ),
              const SizedBox(height: 3),
              Text(
                '${item['pontos']} pts',
                style: TextStyle(
                  color: AppCores.fontes,
                  fontSize: destacado ? 14 : 12,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildClassificacaoModalRow(Map<String, dynamic> item) {
    final pos = item['pos'] as int;
    final cor = item['cor'] as Color?;
    final img = item['img'] as String?;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 10.0),
      decoration: BoxDecoration(
        color: AppCores.branco,
        borderRadius: BorderRadius.circular(12.0),
        border: Border.all(color: AppCores.outline),
      ),
      child: Row(
        children: [
          if (pos <= 3)
            Icon(UIcons.boldRounded.badge, color: cor, size: 22)
          else
            Container(
              width: 26,
              height: 26,
              decoration: BoxDecoration(
                color: AppCores.outline.withValues(alpha: 0.25),
                shape: BoxShape.circle,
              ),
              child: Center(
                child: Text(
                  '$pos',
                  style: const TextStyle(
                    color: AppCores.fontes,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          const SizedBox(width: 12),
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: AppCores.outline.withValues(alpha: 0.3),
              shape: BoxShape.circle,
            ),
            child: ClipOval(
              child: (img != null && img.isNotEmpty)
                  ? Image.network(
                      img,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) {
                        return Image.asset(
                          'assets/images/default_pint.jpg',
                          fit: BoxFit.cover,
                        );
                      },
                      loadingBuilder: (context, child, loadingProgress) {
                        if (loadingProgress == null) return child;
                        return const Center(
                          child: SizedBox(
                            width: 12,
                            height: 12,
                            child: CircularProgressIndicator(
                              strokeWidth: 1.5,
                              color: AppCores.azulFundo,
                            ),
                          ),
                        );
                      },
                    )
                  : Image.asset(
                      'assets/images/default_pint.jpg',
                      fit: BoxFit.cover,
                    ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item['nome'] as String,
                  style: const TextStyle(
                    color: AppCores.fontes,
                    fontSize: 14.0,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Text(
                  item['area'] as String,
                  style: const TextStyle(
                    color: Color(0xFF8796A2),
                    fontSize: 12.0,
                  ),
                ),
              ],
            ),
          ),
          Text(
            '${item['pontos']} pts',
            style: const TextStyle(
              color: AppCores.azulFundo,
              fontSize: 13.0,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}
