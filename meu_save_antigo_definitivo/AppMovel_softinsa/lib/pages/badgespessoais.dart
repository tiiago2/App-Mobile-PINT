import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:uicons/uicons.dart';
import '../variaveis/variaveis.dart';
import '../idiomas/app_localizations.dart';
import '../widgets/top_bar_actions.dart';
import '../widgets/searchbar_filter.dart';
import '../widgets/galeria/divisao_especiais.dart';
import '../widgets/galeria/divisao_minha_area.dart';
import '../widgets/galeria/divisao_outras_areas.dart';
import '../widgets/galeria/galeria_badges_modular.dart';

class BadgesPessoaisScreen extends StatefulWidget {
  const BadgesPessoaisScreen({super.key});

  @override
  State<BadgesPessoaisScreen> createState() => _BadgesPessoaisScreen();
}

class _BadgesPessoaisScreen extends State<BadgesPessoaisScreen> {
  String _pesquisa = '';
  FilterOptions _filterOptions = const FilterOptions();

  final List<Map<String, dynamic>> mockTodosBadges = const [
    {'id': 1, 'titulo': 'Cloud Básico', 'especial': '1', 'area': 'Dev Ops', 'imagem': 'https://i.pravatar.cc/300?img=11', 'dataAquisicao': '2026-05-20', 'validadeDias': 30, 'pontos': 150},
    {'id': 2, 'titulo': 'Low Code Avançado', 'especial': '0', 'area': 'Dev Ops', 'imagem': 'https://i.pravatar.cc/300?img=12', 'dataAquisicao': '2026-06-15', 'validadeDias': 60, 'pontos': 200},
    {'id': 3, 'titulo': 'Scrum Master', 'especial': '0', 'area': 'Design', 'imagem': 'https://i.pravatar.cc/300?img=13', 'dataAquisicao': '2026-07-01', 'pontos': 300},
    {'id': 4, 'titulo': 'DevOps Pro', 'especial': '0', 'area': 'Design', 'imagem': 'https://i.pravatar.cc/300?img=14', 'dataAquisicao': '2025-10-10', 'validadeDias': 365, 'pontos': 500},
  ];

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    // Apply search filter
    var filteredBadges = mockTodosBadges.where((badge) {
      final query = _pesquisa.trim().toLowerCase();
      if (query.isEmpty) return true;
      final title = badge['titulo']?.toString().toLowerCase() ?? '';
      final area = badge['area']?.toString().toLowerCase() ?? '';
      return title.contains(query) || area.contains(query);
    }).toList();

    // Apply Level Filter
    if (_filterOptions.nivel != 'todos') {
      final String lvl = _filterOptions.nivel;
      filteredBadges = filteredBadges.where((b) {
        final nivelNome = (b['nivelNome'] ?? b['nivel'] ?? '').toString().toLowerCase();
        final title = (b['titulo'] ?? '').toString().toLowerCase();
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
      filteredBadges = filteredBadges.where((b) {
        final isEspecial = b['especial'] == true || b['especial'] == '1';
        if (t == 'especial') return isEspecial;
        if (t == 'normal') return !isEspecial;
        return true;
      }).toList();
    }

    // Apply Service Line Filter
    if (_filterOptions.serviceLine != 'todos') {
      final String sl = _filterOptions.serviceLine;
      filteredBadges = filteredBadges.where((b) {
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
      filteredBadges = filteredBadges.where((b) {
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
    filteredBadges.sort((a, b) {
      final nameA = (a['titulo'] ?? '').toString().toLowerCase();
      final nameB = (b['titulo'] ?? '').toString().toLowerCase();
      final ptsA = int.tryParse((a['pontos'] ?? '0').toString()) ?? 0;
      final ptsB = int.tryParse((b['pontos'] ?? '0').toString()) ?? 0;

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

    final listaEspeciais = filteredBadges.where((b) => b['especial'] == '1').toList();
    final listaMinhaArea = filteredBadges.where((b) => b['especial'] != '1' && b['area'] == 'Dev Ops').toList();
    final listaOutrasAreas = filteredBadges.where((b) => b['especial'] != '1' && b['area'] != 'Dev Ops').toList();

    return Scaffold(
      backgroundColor: AppCores.branco,
      appBar: AppBar(
        backgroundColor: AppCores.branco,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
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
          l10n?.badgesPessoais ?? 'Badges Pessoais',
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
              CartaoTotalPontos(pontos: 700),
              SizedBox(height: AppTamanhos.gapBadgesPessoais),
              SearchBarFilter(
                hintText: l10n?.pesquisarBadge ?? 'Pesquisar Badge...',
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
              SizedBox(height: AppTamanhos.gapBadgesPessoais),
              if (listaEspeciais.isNotEmpty) ...[
                DivisaoEspeciais(),
                SizedBox(height: AppTamanhos.gapBadgesPessoais),
                GaleriaBadgesModular(badges: listaEspeciais),
                SizedBox(height: AppTamanhos.gapBadgesPessoais),
              ],
              if (listaMinhaArea.isNotEmpty) ...[
                DivisaoMinhaArea(),
                SizedBox(height: AppTamanhos.gapBadgesPessoais),
                GaleriaBadgesModular(badges: listaMinhaArea),
                SizedBox(height: AppTamanhos.gapBadgesPessoais),
              ],
              if (listaOutrasAreas.isNotEmpty) ...[
                DivisaoOutrasAreas(),
                SizedBox(height: AppTamanhos.gapBadgesPessoais),
                GaleriaBadgesModular(badges: listaOutrasAreas),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class CartaoTotalPontos extends StatelessWidget {
  final int pontos;

  const CartaoTotalPontos({
    super.key,
    required this.pontos,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20.0),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(14.0),
        gradient: const LinearGradient(
          colors: [
            Color(0xFF39639C),
            Color(0xFF4A7FC7),
          ],
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                l10n?.totalPontos ?? 'Total de Pontos Conquistados',
                style: const TextStyle(
                  color: AppCores.branco,
                  fontSize: 12.0,
                  fontWeight: FontWeight.normal,
                ),
              ),
              const SizedBox(height: 4.0),
              Text(
                '$pontos ${l10n?.pts ?? 'pts'}',
                style: const TextStyle(
                  color: AppCores.branco,
                  fontSize: 32.0,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          Icon(
            UIcons.boldRounded.badge,
            color: Colors.white.withValues(alpha: 0.9),
            size: 48.0,
          ),
        ],
      ),
    );
  }
}