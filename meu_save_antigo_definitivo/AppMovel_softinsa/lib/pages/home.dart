import 'package:flutter/material.dart';
import 'package:uicons/uicons.dart';
import 'package:go_router/go_router.dart';
import '../variaveis/variaveis.dart';
import '../idiomas/app_localizations.dart';
import '../widgets/top_bar_actions.dart';
import '../widgets/galeria/badge_item_com_estado_wrapper.dart';
import 'badge_detalhe.dart';
import 'estatisticas.dart';

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

  // 1. Objetivos Propostos Ativos
  final List<Map<String, dynamic>> _mockObjetivosHome = [
    {
      'titulo': 'Low Code Básico',
      'categoria': 'Low Code',
      'deadline': '04/12/2025',
      'diasRestantes': 2,
      'progresso': 0.6,
      'avatarColor': const Color(0xFF82ADE7),
    },
    {
      'titulo': 'Cloud Architect',
      'categoria': 'Cloud Computing',
      'deadline': '10/12/2025',
      'diasRestantes': 8,
      'progresso': 0.3,
      'avatarColor': const Color(0xFFEC4899),
    },
    {
      'titulo': 'Git & Version Control',
      'categoria': 'Development Tools',
      'deadline': '15/12/2025',
      'diasRestantes': 13,
      'progresso': 0.85,
      'avatarColor': const Color(0xFF10B981),
    },
    {
      'titulo': 'Mobile Dev Pro',
      'categoria': 'Mobile Dev',
      'deadline': '22/12/2025',
      'diasRestantes': 20,
      'progresso': 0.15,
      'avatarColor': const Color(0xFF06B6D4),
    },
  ];

  // 2. Badges em Progresso
  final List<Map<String, dynamic>> _mockBadgesEmProgresso = [
    {
      'titulo': 'Low Code',
      'categoria': 'Low Code',
      'estado': 'emProgresso',
      'progresso': 65,
      'especial': false,
      'imagem': null,
      'avatarColor': const Color(0xFF82ADE7),
    },
    {
      'titulo': 'Code Reviewer',
      'categoria': 'Desenvolvimento',
      'estado': 'emProgresso',
      'progresso': 40,
      'especial': false,
      'imagem': null,
      'avatarColor': const Color(0xFF9B6AF7),
    },
    {
      'titulo': 'Database Admin',
      'categoria': 'Infraestrutura',
      'estado': 'emProgresso',
      'progresso': 80,
      'especial': false,
      'imagem': null,
      'avatarColor': const Color(0xFF62C884),
    },
    {
      'titulo': 'Security Ninja',
      'categoria': 'Segurança',
      'estado': 'emProgresso',
      'progresso': 25,
      'especial': true,
      'imagem': null,
      'avatarColor': const Color(0xFFF8AA0B),
    },
    {
      'titulo': 'DevOps Master',
      'categoria': 'DevOps',
      'estado': 'emProgresso',
      'progresso': 50,
      'especial': false,
      'imagem': null,
      'avatarColor': const Color(0xFFE96A6A),
    },
  ];

  // 3. Classificação Geral (Leaderboard Mock)
  final List<Map<String, dynamic>> _mockRanking = [
    {
      'id': 1,
      'posicao': 1,
      'nome': 'João Silva',
      'area': 'Hybrid Systems',
      'service_line': 'Digital',
      'funcao': 'consultor',
      'pontos_semana': 320,
      'pontos_mes': 1850,
      'pontos_ano': 14200,
      'pontos_sempre': 37455,
      'pontos': 37455,
      'img': null,
    },
    {
      'id': 2,
      'posicao': 2,
      'nome': 'Ana Martins',
      'area': 'Low Code',
      'service_line': 'Digital',
      'funcao': 'senior',
      'pontos_semana': 290,
      'pontos_mes': 1600,
      'pontos_ano': 12800,
      'pontos_sempre': 34120,
      'pontos': 34120,
      'img': null,
    },
    {
      'id': 3,
      'posicao': 3,
      'nome': 'Carlos Souza',
      'area': 'Cloud & DevOps',
      'service_line': 'Data',
      'funcao': 'tech_lead',
      'pontos_semana': 260,
      'pontos_mes': 1500,
      'pontos_ano': 11500,
      'pontos_sempre': 31800,
      'pontos': 31800,
      'img': null,
    },
    {
      'id': 4,
      'posicao': 4,
      'nome': 'Mariana Costa',
      'area': 'Mobile Dev',
      'service_line': 'Digital',
      'funcao': 'consultor',
      'pontos_semana': 210,
      'pontos_mes': 1350,
      'pontos_ano': 10200,
      'pontos_sempre': 29500,
      'pontos': 29500,
      'img': null,
    },
    {
      'id': 5,
      'posicao': 5,
      'nome': 'Pedro Santos',
      'area': 'Cyber Security',
      'service_line': 'Cybersecurity',
      'funcao': 'senior',
      'pontos_semana': 190,
      'pontos_mes': 1200,
      'pontos_ano': 9400,
      'pontos_sempre': 27340,
      'pontos': 27340,
      'img': null,
    },
    {
      'id': 6,
      'posicao': 6,
      'nome': 'Sofia Oliveira',
      'area': 'Hybrid Systems',
      'service_line': 'Digital',
      'funcao': 'consultor',
      'pontos_semana': 170,
      'pontos_mes': 1100,
      'pontos_ano': 8600,
      'pontos_sempre': 25100,
      'pontos': 25100,
      'img': null,
    },
    {
      'id': 7,
      'posicao': 7,
      'nome': 'Rui Ferreira',
      'area': 'QA & Testing',
      'service_line': 'Digital',
      'funcao': 'junior',
      'pontos_semana': 150,
      'pontos_mes': 980,
      'pontos_ano': 7800,
      'pontos_sempre': 23450,
      'pontos': 23450,
      'img': null,
    },
    {
      'id': 8,
      'posicao': 8,
      'nome': 'Beatriz Lima',
      'area': 'Data Science',
      'service_line': 'Data',
      'funcao': 'junior',
      'pontos_semana': 130,
      'pontos_mes': 890,
      'pontos_ano': 7100,
      'pontos_sempre': 21900,
      'pontos': 21900,
      'img': null,
    },
    {
      'id': 9,
      'posicao': 9,
      'nome': 'Gonçalo Pereira',
      'area': 'Backend Dev',
      'service_line': 'Digital',
      'funcao': 'junior',
      'pontos_semana': 110,
      'pontos_mes': 800,
      'pontos_ano': 6400,
      'pontos_sempre': 19800,
      'pontos': 19800,
      'img': null,
    },
    {
      'id': 10,
      'posicao': 10,
      'nome': 'Inês Ribeiro',
      'area': 'UI/UX Design',
      'service_line': 'UX/UI',
      'funcao': 'junior',
      'pontos_semana': 90,
      'pontos_mes': 720,
      'pontos_ano': 5900,
      'pontos_sempre': 18250,
      'pontos': 18250,
      'img': null,
    },
  ];

  // ── Card de Objetivo Proposto (Horizontal) ────────────────────────────────
  Widget _buildHomeObjectiveCard(Map<String, dynamic> obj) {
    final String titulo = obj['titulo'] as String;
    final String categoria = obj['categoria'] as String;
    final String deadline = obj['deadline'] as String;
    final int diasRestantes = obj['diasRestantes'] as int;
    final double progresso = obj['progresso'] as double;
    final Color avatarColor = obj['avatarColor'] as Color;

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
              ),
              alignment: Alignment.center,
              child: Icon(
                Icons.bolt_rounded,
                color: avatarColor,
                size: 28,
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
          CircleAvatar(
            radius: avatarSize / 2,
            backgroundColor: AppCores.outline.withOpacity(0.3),
            child: Icon(
              UIcons.boldRounded.portrait,
              color: AppCores.fontes,
              size: avatarSize * 0.5,
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
          CircleAvatar(
            radius: 18,
            backgroundColor: AppCores.outline.withOpacity(0.3),
            child: Icon(
              UIcons.boldRounded.portrait,
              color: AppCores.fontes,
              size: 18,
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
    final l10n = AppLocalizations.of(context)!;
    final top1 = _mockRanking.firstWhere((u) => u['posicao'] == 1);
    final top2 = _mockRanking.firstWhere((u) => u['posicao'] == 2);
    final top3 = _mockRanking.firstWhere((u) => u['posicao'] == 3);
    final restoRanking = _mockRanking.where((u) => (u['posicao'] as int) > 3).toList();

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
      body: SingleChildScrollView(
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
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: AppTamanhos.margemEcra),
                  itemCount: _mockObjetivosHome.length,
                  separatorBuilder: (_, __) => const SizedBox(width: 12.0),
                  itemBuilder: (context, index) {
                    return _buildHomeObjectiveCard(_mockObjetivosHome[index]);
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
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: AppTamanhos.margemEcra),
                  itemCount: _mockBadgesEmProgresso.length,
                  separatorBuilder: (_, __) => const SizedBox(width: 16.0),
                  itemBuilder: (context, index) {
                    return BadgeItemComEstadoWrapper(
                      badge: _mockBadgesEmProgresso[index],
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
                          builder: (_) => ClassificacaoModal(dados: _mockRanking),
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
                  itemCount: restoRanking.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 10.0),
                  itemBuilder: (context, index) {
                    return _buildRankingRowItem(restoRanking[index]);
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
    );
  }
}
