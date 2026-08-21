import 'package:flutter/material.dart';
import 'package:uicons/uicons.dart';
import 'package:go_router/go_router.dart';
import '../variaveis/variaveis.dart';
import '../idiomas/app_localizations.dart';
import '../widgets/top_bar_actions.dart';
import 'badge_detalhe.dart';

class HistoricoBadgesScreen extends StatefulWidget {
  const HistoricoBadgesScreen({super.key});

  @override
  State<HistoricoBadgesScreen> createState() => _HistoricoBadgesScreenState();
}

class _HistoricoBadgesScreenState extends State<HistoricoBadgesScreen> {
  String _selectedTab = 'Todos'; // 'Todos', 'Ativos', 'Expirados'

  // --- MOCK DATA (Histórico de Badges) ---
  final List<Map<String, dynamic>> _mockHistorico = [
    {
      'titulo': 'Git & Version Control',
      'categoria': 'Development Tools',
      'pontos': 100,
      'imagem': null,
      'avatarColor': const Color(0xFF10B981),
      'especial': false,
      'estado': 'conquistado',
      'ativo': true,
      'obtido': '16/12/2022',
      'validade': '16/12/2028',
    },
    {
      'titulo': 'Scrum Master Básico',
      'categoria': 'Low Code',
      'pontos': 150,
      'imagem': null,
      'avatarColor': const Color(0xFFFBBF24),
      'especial': false,
      'estado': 'expirado',
      'ativo': false,
      'obtido': '20/01/2023',
      'validade': '20/01/2026',
      'aviso': 'Este Badge expirou em 20/01/2026. Para manteres as tuas competências atualizadas, é necessário renovar o badge.',
    },
    {
      'titulo': 'Low Code Pro',
      'categoria': 'Low Code',
      'pontos': 350,
      'imagem': null,
      'avatarColor': const Color(0xFF3B82F6),
      'especial': true,
      'estado': 'expirado',
      'ativo': false,
      'obtido': '24/02/2023',
      'validade': '24/02/2026',
      'aviso': 'Este Badge expirou em 24/02/2026. Para manteres as tuas competências atualizadas, é necessário renovar o badge.',
    },
    {
      'titulo': 'OutSystems Fundamentals',
      'categoria': 'Low Code',
      'pontos': 50,
      'imagem': null,
      'avatarColor': const Color(0xFF39639C),
      'especial': false,
      'estado': 'conquistado',
      'ativo': true,
      'obtido': '15/06/2025',
      'validade': '15/06/2029',
    },
    {
      'titulo': 'OutSystems Dev',
      'categoria': 'Low Code',
      'pontos': 200,
      'imagem': null,
      'avatarColor': const Color(0xFFEC4899),
      'especial': false,
      'estado': 'conquistado',
      'ativo': true,
      'obtido': '19/11/2025',
      'validade': '19/11/2026',
    },
    {
      'titulo': 'Cloud Essentials',
      'categoria': 'Cloud Computing',
      'pontos': 150,
      'imagem': null,
      'avatarColor': const Color(0xFF8B5CF6),
      'especial': false,
      'estado': 'conquistado',
      'ativo': true,
      'obtido': '10/01/2026',
      'validade': '10/01/2030',
    },
    {
      'titulo': 'Mobile Dev',
      'categoria': 'Mobile Dev',
      'pontos': 120,
      'imagem': null,
      'avatarColor': const Color(0xFF06B6D4),
      'especial': false,
      'estado': 'conquistado',
      'ativo': true,
      'obtido': '05/02/2026',
      'validade': '05/02/2027',
    },
  ];

  // ── Filtragem dos Badges para a Timeline ──────────────────────────────────
  List<Map<String, dynamic>> get _badgesFiltrados {
    if (_selectedTab == 'Ativos') {
      return _mockHistorico.where((b) => b['ativo'] == true).toList();
    } else if (_selectedTab == 'Expirados') {
      return _mockHistorico.where((b) => b['ativo'] == false).toList();
    }
    return _mockHistorico;
  }

  // ── Estatísticas Superiores ───────────────────────────────────────────────
  int get _total => _mockHistorico.length;
  int get _ativos => _mockHistorico.where((b) => b['ativo'] == true).length;
  int get _expirados => _mockHistorico.where((b) => b['ativo'] == false).length;

  // ── Construção dos Cards de Estatísticas ──────────────────────────────────
  Widget _buildStatCard({
    required String value,
    required String label,
    required Color borderCol,
    required Color bgCol,
    required Color textCol,
  }) {
    return Container(
      width: 110,
      height: 95,
      decoration: BoxDecoration(
        color: bgCol,
        borderRadius: BorderRadius.circular(AppBorders.padrao),
        border: Border.all(color: borderCol, width: 2.0),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            value,
            style: TextStyle(
              color: textCol,
              fontSize: 32.0,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 4.0),
          Text(
            label,
            style: TextStyle(
              color: textCol,
              fontSize: 12.0,
              fontWeight: FontWeight.w300,
            ),
          ),
        ],
      ),
    );
  }

  // ── Construção do Seletor de Abas (Pills) ──────────────────────────────────
  Widget _buildTabPill(String title, String displayLabel) {
    final isSelected = _selectedTab == title;

    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedTab = title;
        });
      },
      child: Container(
        height: 36.0,
        padding: const EdgeInsets.symmetric(horizontal: 20.0),
        decoration: BoxDecoration(
          color: isSelected ? AppCores.azulFundo : AppCores.branco,
          borderRadius: BorderRadius.circular(AppBorders.pilulas),
          border: Border.all(
            color: isSelected ? AppCores.azulFundo : AppCores.outline,
            width: 1.6,
          ),
        ),
        alignment: Alignment.center,
        child: Text(
          displayLabel,
          style: TextStyle(
            color: isSelected ? AppCores.branco : AppCores.fontes,
            fontSize: 14.0,
            fontWeight: FontWeight.w500,
          ),
        ),
      ),
    );
  }

  // ── Placeholder para Avatar com Inicial ───────────────────────────────────
  Widget _buildPlaceholder(String titulo, Color avatarColor, bool especial) {
    final letra = titulo.isNotEmpty ? titulo[0].toUpperCase() : '?';
    return ClipOval(
      child: Container(
        width: 50,
        height: 50,
        color: avatarColor,
        child: Center(
          child: Text(
            letra,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ),
    );
  }

  // ── Item da Timeline ──────────────────────────────────────────────────────
  Widget _buildTimelineItem(Map<String, dynamic> badge, bool isFirst, bool isLast) {
    final bool ativo = badge['ativo'] == true;
    final String titulo = badge['titulo'] as String;
    final String categoria = badge['categoria'] as String;
    final int pontos = badge['pontos'] as int;
    final Color avatarColor = badge['avatarColor'] as Color;
    final bool especial = badge['especial'] as bool;
    final String obtido = badge['obtido'] as String;
    final String validade = badge['validade'] as String;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Coluna da Linha da Timeline
        Stack(
          alignment: Alignment.topCenter,
          children: [
            // Linha Vertical
            Positioned(
              top: isFirst ? 28.0 : 0.0,
              bottom: isLast ? 28.0 : 0.0,
              child: Container(
                width: 2.0,
                color: AppCores.outline,
              ),
            ),
            // Círculo com Avatar
            GestureDetector(
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => BadgeDetalheScreen(badge: badge),
                  ),
                );
              },
              child: Container(
                margin: const EdgeInsets.symmetric(vertical: 2.0),
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppCores.branco,
                  border: Border.all(
                    color: especial ? const Color(0xFFF8AA0B) : AppCores.outline,
                    width: especial ? 2.5 : 1.6,
                  ),
                ),
                padding: const EdgeInsets.all(2.0),
                child: _buildPlaceholder(titulo, avatarColor, especial),
              ),
            ),
          ],
        ),
        const SizedBox(width: 12.0),
        // Card de Conteúdo do Badge
        Expanded(
          child: GestureDetector(
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => BadgeDetalheScreen(badge: badge),
                ),
              );
            },
            child: Container(
              margin: const EdgeInsets.only(bottom: 24.0),
              padding: const EdgeInsets.all(16.0),
              decoration: BoxDecoration(
                color: AppCores.branco,
                borderRadius: BorderRadius.circular(AppBorders.padrao),
                border: Border.all(color: AppCores.outline, width: 1.6),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Título, Categoria e Status
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
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
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const SizedBox(height: 2.0),
                            Text(
                              categoria,
                              style: TextStyle(
                                color: AppCores.fontes.withValues(alpha: 0.5),
                                fontSize: 12.0,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 8.0),
                      // Status Pill
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8.0,
                          vertical: 3.0,
                        ),
                        decoration: BoxDecoration(
                          color: ativo
                              ? const Color(0xFF009966)
                              : const Color(0xFFD42A2A),
                          borderRadius: BorderRadius.circular(12.0),
                        ),
                        child: Text(
                          ativo ? AppLocalizations.of(context)!.ativo : AppLocalizations.of(context)!.expirado,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 10.0,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16.0),
                  // Datas (Obtido e Validade)
                  Row(
                    children: [
                      // Obtido Box
                      Expanded(
                        child: Container(
                          padding: const EdgeInsets.all(8.0),
                          decoration: BoxDecoration(
                            color: AppCores.fundo2,
                            borderRadius: BorderRadius.circular(6.0),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Icon(
                                    UIcons.boldRounded.calendar,
                                    size: 11.0,
                                    color: AppCores.fontes.withValues(alpha: 0.5),
                                  ),
                                  const SizedBox(width: 4.0),
                                  Text(
                                    AppLocalizations.of(context)!.obtido,
                                    style: TextStyle(
                                      color: AppCores.fontes.withValues(alpha: 0.5),
                                      fontSize: 9.0,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 4.0),
                              Text(
                                obtido,
                                style: const TextStyle(
                                  color: AppCores.fontes,
                                  fontSize: 11.0,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(width: 8.0),
                      // Validade Box
                      Expanded(
                        child: Container(
                          padding: const EdgeInsets.all(8.0),
                          decoration: BoxDecoration(
                            color: AppCores.fundo2,
                            borderRadius: BorderRadius.circular(6.0),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Icon(
                                    UIcons.boldRounded.clock,
                                    size: 11.0,
                                    color: AppCores.fontes.withValues(alpha: 0.5),
                                  ),
                                  const SizedBox(width: 4.0),
                                  Text(
                                    AppLocalizations.of(context)!.validade,
                                    style: TextStyle(
                                      color: AppCores.fontes.withValues(alpha: 0.5),
                                      fontSize: 9.0,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 4.0),
                              Text(
                                validade,
                                style: const TextStyle(
                                  color: AppCores.fontes,
                                  fontSize: 11.0,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12.0),
                  // Banner de Aviso (Apenas Expirados)
                  if (!ativo) ...[
                    Container(
                      padding: const EdgeInsets.all(10.0),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFEE2E2),
                        border: Border.all(
                          color: const Color(0xFFD42A2A).withValues(alpha: 0.3),
                        ),
                        borderRadius: BorderRadius.circular(10.0),
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Icon(
                            Icons.history_toggle_off_rounded,
                            color: Color(0xFF991B1B),
                            size: 14.0,
                          ),
                          const SizedBox(width: 6.0),
                          Expanded(
                            child: Text(
                              '${AppLocalizations.of(context)!.avisoExpiradoParte1}$validade${AppLocalizations.of(context)!.avisoExpiradoParte2}',
                              style: const TextStyle(
                                color: Color(0xFF991B1B),
                                fontSize: 9.5,
                                height: 1.4,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 12.0),
                  ],
                  // Pontos Pill
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8.0,
                      vertical: 4.0,
                    ),
                    decoration: BoxDecoration(
                      color: AppCores.azulFundo,
                      borderRadius: BorderRadius.circular(50.0),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          UIcons.boldRounded.graduation_cap,
                          color: Colors.white,
                          size: 11.0,
                        ),
                        const SizedBox(width: 4.0),
                        Text(
                          '$pontos pts',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 10.0,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  // ── Build ─────────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final listItems = _badgesFiltrados;

    return Scaffold(
      backgroundColor: AppCores.branco,
      appBar: AppBar(
        backgroundColor: AppCores.branco,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(
            UIcons.boldRounded.angle_small_left,
            color: AppCores.fontes,
            size: AppTamanhos.iconeNavegacao,
          ),
          onPressed: () {
            if (GoRouter.of(context).canPop()) {
              context.pop();
            } else {
              Navigator.of(context).maybePop();
            }
          },
        ),
        titleSpacing: 0,
        title: Text(
          AppLocalizations.of(context)?.historicoTitulo ?? 'Histórico de Badges',
          style: const TextStyle(color: AppCores.fontes, fontSize: AppTamanhos.titulo),
        ),
        actions: const [
          TopBarActions(showDocumentIcon: false),
        ],
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(AppTamanhos.margemEcra),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // 1. Estatísticas Superiores (Row com os 3 cards)
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  _buildStatCard(
                    value: '$_total',
                    label: l10n.total,
                    borderCol: AppCores.outline,
                    bgCol: AppCores.fundo2,
                    textCol: AppCores.fontes,
                  ),
                  _buildStatCard(
                    value: '$_ativos',
                    label: l10n.abaAtivos,
                    borderCol: const Color(0xFF009966),
                    bgCol: const Color(0xFFD1FAE5),
                    textCol: const Color(0xFF065F46),
                  ),
                  _buildStatCard(
                    value: '$_expirados',
                    label: l10n.abaExpirados,
                    borderCol: const Color(0xFFD42A2A),
                    bgCol: const Color(0xFFFEE2E2),
                    textCol: const Color(0xFF991B1B),
                  ),
                ],
              ),
              const SizedBox(height: 24.0),
              // 2. Seletor de Abas (Todos / Ativos / Expirados)
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  _buildTabPill('Todos', l10n.todos),
                  const SizedBox(width: 8.0),
                  _buildTabPill('Ativos', l10n.abaAtivos),
                  const SizedBox(width: 8.0),
                  _buildTabPill('Expirados', l10n.abaExpirados),
                ],
              ),
              const SizedBox(height: 24.0),
              // 3. Timeline com Badges
              if (listItems.isEmpty)
                Center(
                  child: Padding(
                    padding: const EdgeInsets.all(32.0),
                    child: Text(
                      l10n.semBadgesSeccao,
                      style: TextStyle(
                        color: AppCores.fontes.withValues(alpha: 0.5),
                        fontSize: 14.0,
                      ),
                    ),
                  ),
                )
              else
                ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: listItems.length,
                  itemBuilder: (context, index) {
                    return _buildTimelineItem(
                      listItems[index],
                      index == 0,
                      index == listItems.length - 1,
                    );
                  },
                ),
            ],
          ),
        ),
      ),
    );
  }
}
