import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:uicons/uicons.dart';
import '../variaveis/variaveis.dart';
import '../widgets/top_bar_actions.dart';
import '../widgets/searchbar_filter.dart';
import '../widgets/filter_chips_list.dart';
import '../widgets/badge_card.dart';
import '../idiomas/app_localizations.dart';

class CandidaturasScreen extends StatefulWidget {
  const CandidaturasScreen({super.key});

  @override
  State<CandidaturasScreen> createState() => _CandidaturasScreenState();
}

class _CandidaturasScreenState extends State<CandidaturasScreen> {
  String _filtroSelecionado = 'todos';
  String _pesquisa = '';
  FilterOptions _filterOptions = const FilterOptions();

  final List<Map<String, dynamic>> mockBadges = [
    {
      'title': 'Low Code Básico',
      'category': 'Low Code',
      'points': 150,
      'icon': UIcons.boldRounded.coffee,
      'avatarColor': const Color(0xFF39639C), // Blue
      'status': BadgeCardStatus.aprovado,
      'date': DateTime(2025, 5, 22),
    },
    {
      'title': 'Low Code Expert',
      'category': 'Low Code',
      'points': 200,
      'icon': UIcons.boldRounded.database,
      'avatarColor': const Color(0xFF10B981), // Green
      'status': BadgeCardStatus.aprovado,
      'date': DateTime(2026, 2, 23),
    },
    {
      'title': 'UX/UI Design',
      'category': 'Design',
      'points': 200,
      'icon': Icons.design_services_rounded,
      'avatarColor': const Color(0xFF8B5CF6), // Purple
      'status': BadgeCardStatus.emProgresso,
      'progressPercentage': 45,
    },
    {
      'title': 'Flutter Avançado',
      'category': 'Mobile Dev',
      'points': 350,
      'icon': UIcons.boldRounded.mobile_button,
      'avatarColor': const Color(0xFF06B6D4), // Cyan
      'status': BadgeCardStatus.pendente,
      'date': DateTime(2023, 10, 1),
    },
    {
      'title': 'Python Básico',
      'category': 'Backend',
      'points': 100,
      'icon': UIcons.boldRounded.database,
      'avatarColor': const Color(0xFFF97316), // Orange
      'status': BadgeCardStatus.recusado,
      'date': DateTime(2023, 2, 15),
    },
    {
      'title': 'Agile Fundamentals',
      'category': 'Management',
      'points': 50,
      'icon': UIcons.boldRounded.users,
      'avatarColor': const Color(0xFFEF4444), // Red
      'status': BadgeCardStatus.recusado,
      'date': DateTime(2023, 2, 15),
    },
    {
      'title': 'Scrum Master',
      'category': 'CyberSecurity',
      'points': 160,
      'icon': UIcons.boldRounded.bullseye,
      'avatarColor': const Color(0xFFFBBF24), // Yellow
      'status': BadgeCardStatus.expirado,
      'date': DateTime(2026, 2, 20),
    },
  ];

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    mockBadges[6]['alertMessage'] = l10n.badgeExpiradoAlert;

    // 1. Filter by search query
    var searchedBadges = mockBadges.where((badge) {
      final query = _pesquisa.trim().toLowerCase();
      if (query.isEmpty) return true;
      final title = badge['title']?.toString().toLowerCase() ?? '';
      final category = badge['category']?.toString().toLowerCase() ?? '';
      return title.contains(query) || category.contains(query);
    }).toList();

    // Apply Level Filter
    if (_filterOptions.nivel != 'todos') {
      final String lvl = _filterOptions.nivel;
      searchedBadges = searchedBadges.where((b) {
        final nivelNome = (b['nivelNome'] ?? b['nivel'] ?? '').toString().toLowerCase();
        final title = (b['title'] ?? b['titulo'] ?? '').toString().toLowerCase();
        if (lvl == 'basico') return nivelNome.contains('básico') || nivelNome.contains('basico') || title.contains('básico') || title.contains('basico') || title.contains('practitioner');
        if (lvl == 'intermedio') return nivelNome.contains('intermédio') || nivelNome.contains('intermedio') || title.contains('intermédio') || title.contains('intermedio') || title.contains('master');
        if (lvl == 'senior') return nivelNome.contains('sénior') || nivelNome.contains('senior') || title.contains('sénior') || title.contains('senior') || title.contains('pro') || title.contains('avançado') || title.contains('avancado');
        if (lvl == 'especialista') return nivelNome.contains('especialista') || title.contains('especialista');
        if (lvl == 'lider') return nivelNome.contains('líder') || nivelNome.contains('lider') || title.contains('líder') || title.contains('lider');
        return true;
      }).toList();
    }

    // Apply Type Filter
    if (_filterOptions.tipo != 'todos') {
      final String t = _filterOptions.tipo;
      searchedBadges = searchedBadges.where((b) {
        final isEspecial = b['especial'] == true || b['especial'] == '1';
        if (t == 'especial') return isEspecial;
        if (t == 'normal') return !isEspecial;
        return true;
      }).toList();
    }

    // Apply Service Line Filter
    if (_filterOptions.serviceLine != 'todos') {
      final String sl = _filterOptions.serviceLine;
      searchedBadges = searchedBadges.where((b) {
        final title = (b['title'] ?? b['titulo'] ?? b['nome'] ?? '').toString().toLowerCase();
        final area = (b['area'] ?? b['areaNome'] ?? b['category'] ?? '').toString().toLowerCase();
        if (sl == 'cloud') return area.contains('cloud') || title.contains('cloud') || title.contains('aws');
        if (sl == 'appdev') return area.contains('dev') || area.contains('low') || area.contains('design') || title.contains('flutter') || title.contains('java') || title.contains('scrum') || title.contains('outsystems');
        if (sl == 'enterprise') return title.contains('sap') || title.contains('salesforce') || title.contains('oracle');
        if (sl == 'security') return area.contains('security') || area.contains('segurança') || area.contains('cyber') || title.contains('security') || title.contains('segurança') || title.contains('cyber');
        return true;
      }).toList();
    }

    // Apply Learning Path Filter
    if (_filterOptions.learningPath != 'todos') {
      final String lp = _filterOptions.learningPath;
      searchedBadges = searchedBadges.where((b) {
        final title = (b['title'] ?? b['titulo'] ?? b['nome'] ?? '').toString().toLowerCase();
        final areaVal = (b['area'] ?? b['areaNome'] ?? b['category'] ?? '').toString().toLowerCase();
        if (lp == 'digital_innovation') return title.contains('digital') || title.contains('innovation');
        if (lp == 'cloud_solutions') return areaVal.contains('cloud') || title.contains('cloud') || title.contains('aws');
        if (lp == 'lowcode_agile') return areaVal.contains('low') || title.contains('low') || title.contains('outsystems') || title.contains('scrum');
        if (lp == 'cybersecurity') return areaVal.contains('security') || areaVal.contains('segurança') || areaVal.contains('cyber') || title.contains('security') || title.contains('segurança') || title.contains('cyber');
        if (lp == 'devops_agile') return areaVal.contains('dev') || title.contains('devops') || title.contains('agile');
        return true;
      }).toList();
    }

    // Apply Sorting
    searchedBadges.sort((a, b) {
      final nameA = (a['title'] ?? a['titulo'] ?? '').toString().toLowerCase();
      final nameB = (b['title'] ?? b['titulo'] ?? '').toString().toLowerCase();
      final ptsA = int.tryParse((a['points'] ?? a['pontos'] ?? '0').toString()) ?? 0;
      final ptsB = int.tryParse((b['points'] ?? b['pontos'] ?? '0').toString()) ?? 0;

      if (_filterOptions.ordenarPor == 'nome_asc') {
        return nameA.compareTo(nameB);
      } else if (_filterOptions.ordenarPor == 'nome_desc') {
        return nameB.compareTo(nameA);
      } else if (_filterOptions.ordenarPor == 'pontos_asc') {
        return ptsA.compareTo(ptsB);
      } else if (_filterOptions.ordenarPor == 'pontos_desc') {
        return ptsB.compareTo(ptsA);
      }
      return 0;
    });

    // 2. Filter by status chip
    final filteredBadges = searchedBadges.where((badge) {
      if (_filtroSelecionado == 'todos') return true;
      if (_filtroSelecionado == 'concluidos') {
        return badge['status'] == BadgeCardStatus.aprovado;
      }
      if (_filtroSelecionado == 'expirados') {
        return badge['status'] == BadgeCardStatus.expirado;
      }
      if (_filtroSelecionado == 'recusados') {
        return badge['status'] == BadgeCardStatus.recusado;
      }
      if (_filtroSelecionado == 'pendentes') {
        return badge['status'] == BadgeCardStatus.pendente;
      }
      if (_filtroSelecionado == 'emProgresso') {
        return badge['status'] == BadgeCardStatus.emProgresso;
      }
      return true;
    }).toList();

    // 3. Compute dynamic counts
    final int countTodos = searchedBadges.length;
    final int countConcluidos = searchedBadges.where((b) => b['status'] == BadgeCardStatus.aprovado).length;
    final int countExpirados = searchedBadges.where((b) => b['status'] == BadgeCardStatus.expirado).length;
    final int countRecusados = searchedBadges.where((b) => b['status'] == BadgeCardStatus.recusado).length;
    final int countPendentes = searchedBadges.where((b) => b['status'] == BadgeCardStatus.pendente).length;
    final int countEmProgresso = searchedBadges.where((b) => b['status'] == BadgeCardStatus.emProgresso).length;

    final Map<String, int> filtros = {
      'todos': countTodos,
      'concluidos': countConcluidos,
      'expirados': countExpirados,
      'recusados': countRecusados,
      'pendentes': countPendentes,
      'emProgresso': countEmProgresso,
    };

    return Scaffold(
      backgroundColor: AppCores.branco,
      appBar: AppBar(
        backgroundColor: AppCores.branco,
        surfaceTintColor: Colors.transparent,
        elevation: 0, // Sem sombra
        leading: IconButton(
          icon: Icon(UIcons.boldRounded.angle_small_left, color: AppCores.fontes, size: AppTamanhos.iconeNavegacao),
          onPressed: () {
            if (GoRouter.of(context).canPop()) {
              context.pop();
            } else {
              context.go('/home');
            }
          },
        ),
        centerTitle: false,
        titleSpacing: 0,
        title: Text(
          l10n.candidaturasTitulo,
          style: const TextStyle(color: AppCores.fontes, fontSize: AppTamanhos.titulo),
        ),
        actions: const [
          TopBarActions(showDocumentIcon: false),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(AppTamanhos.margemEcra),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 19.0, vertical: 17.0),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [
                    Color(0xFF39639C), // AppCores.azulFundo
                    Color(0xFF4A7FC7),
                  ],
                  begin: Alignment.centerLeft,
                  end: Alignment.centerRight,
                ),
                borderRadius: BorderRadius.circular(AppBorders.padrao),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        l10n.totalPontos,
                        style: const TextStyle(
                          color: Color(0xFFE2E8F0), // Lighter color for subtext
                          fontSize: 12.0,
                          fontWeight: FontWeight.w400,
                        ),
                      ),
                      const SizedBox(height: 8.0),
                      Text(
                        '700 ${l10n.pts}',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 32.0,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  Icon(
                    UIcons.boldRounded.badge,
                    color: const Color(0xFFE2E8F0),
                    size: 40.0,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12.0),
            SearchBarFilter(
              hintText: l10n.pesquisarBadge,
              onChanged: (value) {
                setState(() {
                  _pesquisa = value;
                });
              },
              filterOptions: _filterOptions,
              onFilterChanged: (newOptions) {
                setState(() {
                  _filterOptions = newOptions;
                });
              },
            ),
            const SizedBox(height: 12.0),
            FilterChipsList(
              filtroSelecionado: _filtroSelecionado,
              filtros: filtros,
              onFilterChanged: (newFilter) {
                setState(() {
                  _filtroSelecionado = newFilter;
                });
              },
            ),
            const SizedBox(height: 16.0), // Gap before the list of cards
            Expanded(
              child: ListView.separated(
                itemCount: filteredBadges.length,
                separatorBuilder: (context, index) => const SizedBox(height: 16),
                itemBuilder: (context, index) {
                  final badge = filteredBadges[index];
                  return BadgeCard(
                    title: badge['title'],
                    category: badge['category'],
                    points: badge['points'],
                    icon: badge['icon'],
                    avatarColor: badge['avatarColor'],
                    status: badge['status'],
                    date: badge['date'],
                    progressPercentage: badge['progressPercentage'],
                    alertMessage: badge['alertMessage'],
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}