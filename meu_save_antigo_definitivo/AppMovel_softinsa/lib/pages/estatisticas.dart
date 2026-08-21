import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:uicons/uicons.dart';
import '../variaveis/variaveis.dart';
import '../idiomas/app_localizations.dart';
import '../widgets/top_bar_actions.dart';

import '../controllers/estatisticas_controller.dart';
import '../controllers/objetivos_controller.dart';
import '../controllers/badges_controller.dart';

class EstatisticasScreen extends StatefulWidget {
  const EstatisticasScreen({super.key});

  @override
  State<EstatisticasScreen> createState() => _EstatisticasScreenState();
}

class _EstatisticasScreenState extends State<EstatisticasScreen> {
  String _pointsPeriod = 'Mês';
  String _badgesPeriod = 'Trim';
  String _distribuicaoAno = '2024';

  final List<String> _anosDistribuicao = const ['2022', '2023', '2024', '2025'];

  @override
  void initState() {
    super.initState();
    EstatisticasController.instance.carregar();
    ObjetivosController.instance.carregar();
    BadgesController.instance.carregar();
  }

  List<Map<String, dynamic>> _obterClassificacao() {
    final users = EstatisticasController.instance.rankingGeral;
    if (users.isEmpty) return _mockClassificacao;
    return users.map((u) {
      final pontos = (u['pontos_totais'] as num?)?.toInt() ?? 0;
      return {
        'id': u['id_utilizador'] ?? 0,
        'nome': u['nome_user'] ?? '',
        'area': u['nome_area'] ?? 'Geral',
        'service_line': u['nome_service_line'] ?? 'Consultoria',
        'funcao': 'consultor',
        'pontos_semana': (pontos * 0.1).round(),
        'pontos_mes': (pontos * 0.3).round(),
        'pontos_ano': (pontos * 0.8).round(),
        'pontos_sempre': pontos,
        'img': u['imagem_perfil'],
      };
    }).toList();
  }

  // ── MOCKS ───────────────────────────────────────────────────────────────
  final List<Map<String, dynamic>> _mockClassificacao = const [
    {
      'id': 1,
      'nome': 'Ana S.',
      'area': 'Cloud',
      'service_line': 'Digital',
      'funcao': 'consultor',
      'pontos_semana': 245,
      'pontos_mes': 1200,
      'pontos_ano': 8400,
      'pontos_sempre': 12450,
      'img': 'https://i.pravatar.cc/150?img=47',
    },
    {
      'id': 2,
      'nome': 'Pedro A.',
      'area': 'Security',
      'service_line': 'Cybersecurity',
      'funcao': 'senior',
      'pontos_semana': 180,
      'pontos_mes': 1150,
      'pontos_ano': 7200,
      'pontos_sempre': 11200,
      'img': 'https://i.pravatar.cc/150?img=12',
    },
    {
      'id': 3,
      'nome': 'João M.',
      'area': 'Low Code',
      'service_line': 'Digital',
      'funcao': 'consultor',
      'pontos_semana': 210,
      'pontos_mes': 1100,
      'pontos_ano': 6800,
      'pontos_sempre': 10800,
      'img': 'https://i.pravatar.cc/150?img=15',
    },
    {
      'id': 4,
      'nome': 'Maria F.',
      'area': 'Design',
      'service_line': 'UX/UI',
      'funcao': 'senior',
      'pontos_semana': 150,
      'pontos_mes': 1050,
      'pontos_ano': 6100,
      'pontos_sempre': 9800,
      'img': 'https://i.pravatar.cc/150?img=49',
    },
    {
      'id': 5,
      'nome': 'Rui P.',
      'area': 'Cloud',
      'service_line': 'Data',
      'funcao': 'tech_lead',
      'pontos_semana': 120,
      'pontos_mes': 1000,
      'pontos_ano': 5900,
      'pontos_sempre': 9400,
      'img': 'https://i.pravatar.cc/150?img=33',
    },
    {
      'id': 6,
      'nome': 'Sofia C.',
      'area': 'Security',
      'service_line': 'Cybersecurity',
      'funcao': 'consultor',
      'pontos_semana': 90,
      'pontos_mes': 850,
      'pontos_ano': 5200,
      'pontos_sempre': 8100,
      'img': 'https://i.pravatar.cc/150?img=44',
    },
    {
      'id': 7,
      'nome': 'Tiago R.',
      'area': 'Low Code',
      'service_line': 'Digital',
      'funcao': 'junior',
      'pontos_semana': 110,
      'pontos_mes': 780,
      'pontos_ano': 4600,
      'pontos_sempre': 7200,
      'img': 'https://i.pravatar.cc/150?img=11',
    },
    {
      'id': 8,
      'nome': 'Inês L.',
      'area': 'Design',
      'service_line': 'UX/UI',
      'funcao': 'junior',
      'pontos_semana': 75,
      'pontos_mes': 620,
      'pontos_ano': 3800,
      'pontos_sempre': 5900,
      'img': 'https://i.pravatar.cc/150?img=5',
    },
  ];

  final List<Map<String, dynamic>> _mockDistribuicaoBadges = const [
    {'Nome_Area': 'Cloud', 'total_badges': 42, 'cor': 0xFF39639C},
    {'Nome_Area': 'Security', 'total_badges': 28, 'cor': 0xFF5EA500},
    {'Nome_Area': 'Design', 'total_badges': 18, 'cor': 0xFFE17100},
    {'Nome_Area': 'Low Code', 'total_badges': 12, 'cor': 0xFF1C8CAE},
  ];

  final List<Map<String, dynamic>> _mockNiveis = const [
    {'label': 'Junior', 'value': 12, 'color': 0xFF5EA500},
    {'label': 'Intermédio', 'value': 24, 'color': 0xFF1C8CAE},
    {'label': 'Sénior', 'value': 36, 'color': 0xFFE17100},
    {'label': 'Especialista', 'value': 18, 'color': 0xFFAE012F},
    {'label': 'Líder de conhec.', 'value': 10, 'color': 0xFF45556C},
  ];

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: Listenable.merge([
        EstatisticasController.instance,
        ObjetivosController.instance,
        BadgesController.instance,
      ]),
      builder: (context, _) {
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
      },
    );
  }

  // ── KPI ─────────────────────────────────────────────────────────────────
  Widget _buildKpiGrid() {
    final l10n = AppLocalizations.of(context);
    final estatisticasController = EstatisticasController.instance;
    final objetivosController = ObjetivosController.instance;
    final totalBadges = estatisticasController.totalBadgesConquistados;
    final posicao = estatisticasController.posicaoGeral;
    final objetivosAtivos = objetivosController.objetivosAtivos.length;

    final kpiCards = [
      {
        'icon': UIcons.boldRounded.badge,
        'iconColor': AppCores.azulFundo,
        'value': '$totalBadges',
        'label': l10n?.totalBadgesKpi ?? 'Total de Badges',
      },
      {
        'icon': UIcons.boldRounded.trophy,
        'iconColor': const Color(0xFF5EA500),
        'value': '$posicao.º',
        'label': l10n?.lugarGeralKpi ?? 'Lugar geral',
      },
      {
        'icon': UIcons.boldRounded.chart_histogram,
        'iconColor': const Color(0xFFE17100),
        'value': '${estatisticasController.totalPontos} pts',
        'label': l10n?.mediaProgressoKpi ?? 'Total de Pontos',
      },
      {
        'icon': UIcons.boldRounded.target,
        'iconColor': const Color(0xFFAE012F),
        'value': '$objetivosAtivos',
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
    final total = _mockDistribuicaoBadges.fold<int>(
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
              _buildAnoDistribuicao(),
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
                        sections: _mockDistribuicaoBadges.map((item) {
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
                  children: _mockDistribuicaoBadges.map((item) {
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
      mainAxisSize: MainAxisSize.min,
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
        Text(
          '$label: ',
          style: const TextStyle(
            color: AppCores.fontes,
            fontSize: 12.0,
            fontWeight: FontWeight.w500,
          ),
        ),
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
    final copia = List<Map<String, dynamic>>.from(_obterClassificacao());
    copia.sort((a, b) => ((b['pontos_sempre'] as num?)?.toInt() ?? 0).compareTo((a['pontos_sempre'] as num?)?.toInt() ?? 0));

    return copia.asMap().entries.map((entry) {
      final idx = entry.key;
      final item = entry.value;
      final pos = idx + 1;
      return {
        ...item,
        'pos': pos,
        'pontos': (item['pontos_sempre'] ?? 0).toString(),
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
        CircleAvatar(
          radius: compact ? 16 : 20,
          backgroundColor: AppCores.outline.withValues(alpha: 0.3),
          backgroundImage: img != null ? NetworkImage(img) : null,
          child: img == null
              ? Icon(
                  UIcons.boldRounded.user,
                  color: AppCores.fontes,
                  size: compact ? 14 : 18,
                )
              : null,
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
      builder: (_) => ClassificacaoModal(dados: _obterClassificacao()),
    );
  }

  // ── BADGES POR NÍVEL ────────────────────────────────────────────────────
  Widget _buildBadgesByLevelCard() {
    final total = _mockNiveis.fold<int>(
      0,
      (sum, item) => sum + (item['value'] as int),
    );
    final maxValue = _mockNiveis
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
            children: _mockNiveis.map((level) {
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
    final l10n = AppLocalizations.of(context);
    final Map<String, List<Map<String, dynamic>>> badgeEvolutionData = {
      'Sem': [
        {'label': l10n?.segundaAbbr ?? 'Seg', 'value': 2.0},
        {'label': l10n?.tercaAbbr ?? 'Ter', 'value': 5.0},
        {'label': l10n?.quartaAbbr ?? 'Qua', 'value': 3.0},
        {'label': l10n?.quintaAbbr ?? 'Qui', 'value': 8.0},
        {'label': l10n?.sextaAbbr ?? 'Sex', 'value': 6.0},
        {'label': l10n?.sabadoAbbr ?? 'Sáb', 'value': 1.0},
        {'label': l10n?.domingoAbbr ?? 'Dom', 'value': 4.0},
      ],
      'Mês': [
        {'label': '${l10n?.semanaLabel ?? 'Sem'} 1', 'value': 12.0},
        {'label': '${l10n?.semanaLabel ?? 'Sem'} 2', 'value': 18.0},
        {'label': '${l10n?.semanaLabel ?? 'Sem'} 3', 'value': 15.0},
        {'label': '${l10n?.semanaLabel ?? 'Sem'} 4', 'value': 22.0},
      ],
      'Trim': [
        {'label': l10n?.janeiroAbbr ?? 'Jan', 'value': 20.0},
        {'label': l10n?.fevereiroAbbr ?? 'Fev', 'value': 35.0},
        {'label': l10n?.marcoAbbr ?? 'Mar', 'value': 30.0},
        {'label': l10n?.abrilAbbr ?? 'Abr', 'value': 55.0},
        {'label': l10n?.maioAbbr ?? 'Mai', 'value': 45.0},
        {'label': l10n?.junhoAbbr ?? 'Jun', 'value': 70.0},
      ],
      'Ano': [
        {'label': '2021', 'value': 120.0},
        {'label': '2022', 'value': 180.0},
        {'label': '2023', 'value': 240.0},
        {'label': '2024', 'value': 310.0},
      ],
    };

    final currentData = badgeEvolutionData[_badgesPeriod]!;
    final maxY = currentData.map((e) => e['value'] as double).reduce((a, b) => a > b ? a : b) * 1.2;
    final spots = currentData.asMap().entries.map((entry) {
      return FlSpot(entry.key.toDouble(), entry.value['value']);
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
    final l10n = AppLocalizations.of(context);
    final Map<String, List<Map<String, dynamic>>> pointsEvolutionData = {
      'Sem': [
        {'label': '5/7', 'value': 0.0},
        {'label': '6/7', 'value': 0.0},
        {'label': '7/7', 'value': 1235.0},
        {'label': '8/7', 'value': 0.0},
        {'label': '9/7', 'value': 343.0},
        {'label': '10/7', 'value': 0.0},
        {'label': '11/7', 'value': 0.0},
      ],
      'Mês': [
        {'label': '${l10n?.semanaLabel ?? 'Sem'} 1', 'value': 450.0},
        {'label': '${l10n?.semanaLabel ?? 'Sem'} 2', 'value': 1235.0},
        {'label': '${l10n?.semanaLabel ?? 'Sem'} 3', 'value': 780.0},
        {'label': '${l10n?.semanaLabel ?? 'Sem'} 4', 'value': 343.0},
      ],
      'Trim': [
        {'label': '${l10n?.mesLabel ?? 'Mês'} 1', 'value': 1800.0},
        {'label': '${l10n?.mesLabel ?? 'Mês'} 2', 'value': 2350.0},
        {'label': '${l10n?.mesLabel ?? 'Mês'} 3', 'value': 1580.0},
      ],
      'Ano': [
        {'label': '2021', 'value': 5200.0},
        {'label': '2022', 'value': 7800.0},
        {'label': '2023', 'value': 9500.0},
        {'label': '2024', 'value': 12400.0},
      ],
    };

    final currentData = pointsEvolutionData[_pointsPeriod]!;
    final double maxY = currentData.map((e) => e['value'] as double).reduce((a, b) => a > b ? a : b) * 1.25;
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

  Widget _buildAnoDistribuicao() {
    return GestureDetector(
      onTap: () => _showAnoSelector(context),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 7.0),
        decoration: BoxDecoration(
          color: const Color(0xFFF8FAFC),
          borderRadius: BorderRadius.circular(20.0),
          border: Border.all(color: AppCores.outline),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.03),
              blurRadius: 6,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              _distribuicaoAno,
              style: const TextStyle(
                color: AppCores.fontes,
                fontSize: 12.0,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(width: 4),
            const Icon(
              Icons.keyboard_arrow_down,
              color: AppCores.fontes,
              size: 16.0,
            ),
          ],
        ),
      ),
    );
  }

  void _showAnoSelector(BuildContext context) {
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
                AppLocalizations.of(context)?.selecionarAno ?? 'Selecionar ano',
                style: const TextStyle(
                  color: AppCores.fontes,
                  fontSize: 16.0,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),
              ..._anosDistribuicao.map((ano) {
                final selected = _distribuicaoAno == ano;
                return GestureDetector(
                  onTap: () {
                    setState(() => _distribuicaoAno = ano);
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
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          ano,
                          style: TextStyle(
                            color: selected ? AppCores.azulFundo : AppCores.fontes,
                            fontSize: 14.0,
                            fontWeight: selected ? FontWeight.w600 : FontWeight.w500,
                          ),
                        ),
                        if (selected)
                          Icon(
                            UIcons.boldRounded.check,
                            color: AppCores.azulFundo,
                            size: 16,
                          ),
                      ],
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

  final List<String> _filtroOpcoes = const ['area', 'service_line', 'funcao'];
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
        .map((u) => u[categoria] as String?)
        .where((v) => v != null)
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
          ...valores.map((val) {
            return _buildSubMenuItem(
              label: val,
              selected: _filtroValor == val,
              onTap: () => setState(() {
                _filtroValor = val;
                _subMenuAberto = false;
              }),
            );
          }),
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
              CircleAvatar(
                radius: destacado ? 24 : 18,
                backgroundColor: AppCores.outline.withValues(alpha: 0.3),
                backgroundImage: img != null ? NetworkImage(img) : null,
                child: img == null
                    ? Icon(UIcons.boldRounded.user, color: AppCores.fontes, size: destacado ? 18 : 14)
                    : null,
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
          CircleAvatar(
            radius: 18,
            backgroundColor: AppCores.outline.withValues(alpha: 0.3),
            backgroundImage: img != null ? NetworkImage(img) : null,
            child: img == null
                ? Icon(UIcons.boldRounded.user, color: AppCores.fontes, size: 16)
                : null,
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
