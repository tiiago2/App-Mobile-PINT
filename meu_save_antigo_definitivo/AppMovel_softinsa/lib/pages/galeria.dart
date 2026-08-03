import 'package:flutter/material.dart';
import '../variaveis/variaveis.dart';
import '../widgets/top_bar_actions.dart';
import '../widgets/galeria/aba_todos_badges.dart';
import '../widgets/galeria/aba_sugeridos.dart';
import '../widgets/searchbar_filter.dart';
import '../idiomas/app_localizations.dart';
import '../controllers/galeria_controller.dart';

class GaleriaScreen extends StatefulWidget {
  final String filtroInicial;
  const GaleriaScreen({super.key, this.filtroInicial = 'todos'});

  @override
  State<GaleriaScreen> createState() => _GaleriaScreenState();
}

class _GaleriaScreenState extends State<GaleriaScreen> {
  int _abaSelecionada = 1;
  String _pesquisa = '';
  late String _filtroSelecionado;
  FilterOptions _filterOptions = const FilterOptions();

  @override
  void initState() {
    super.initState();
    _filtroSelecionado = widget.filtroInicial;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      GaleriaController.instance.carregarDados();
    });
  }

  @override
  void didUpdateWidget(covariant GaleriaScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.filtroInicial != oldWidget.filtroInicial) {
      _filtroSelecionado = widget.filtroInicial;
    }
  }



  List<Map<String, dynamic>> _filtrarBadges(List<Map<String, dynamic>> badges) {
    final query = _pesquisa.trim().toLowerCase();

    var filtered = query.isEmpty
        ? List<Map<String, dynamic>>.from(badges)
        : badges.where((badge) => _textoBadge(badge).contains(query)).toList();

    // Apply Level Filter
    if (_filterOptions.nivel != 'todos') {
      final String lvl = _filterOptions.nivel;
      filtered = filtered.where((b) {
        final nivel = b['nivel'];
        final nivelNome = (nivel is Map<String, dynamic> ? nivel['nome_nivel'] : b['nivelNome'] ?? '').toString().toLowerCase();
        final title = (b['titulo'] ?? b['nome_badge'] ?? '').toString().toLowerCase();
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
      filtered = filtered.where((b) {
        final isEspecial = b['especial'] == true || b['especial'] == '1';
        if (t == 'especial') return isEspecial;
        if (t == 'normal') return !isEspecial;
        return true;
      }).toList();
    }

    // Apply Service Line Filter
    if (_filterOptions.serviceLine != 'todos') {
      final String sl = _filterOptions.serviceLine;
      filtered = filtered.where((b) {
        final title = (b['title'] ?? b['titulo'] ?? b['nome'] ?? b['nome_badge'] ?? '').toString().toLowerCase();
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
      filtered = filtered.where((b) {
        final title = (b['title'] ?? b['titulo'] ?? b['nome'] ?? b['nome_badge'] ?? '').toString().toLowerCase();
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
    filtered.sort((a, b) {
      final nameA = (a['titulo'] ?? a['nome_badge'] ?? '').toString().toLowerCase();
      final nameB = (b['titulo'] ?? b['nome_badge'] ?? '').toString().toLowerCase();
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

    return filtered;
  }

  String _textoBadge(Map<String, dynamic> badge) {
    final area = badge['area'];
    final nivel = badge['nivel'];
    final areaNome =
        area is Map<String, dynamic> ? area['nome_area'] : badge['areaNome'];
    final nivelNome =
        nivel is Map<String, dynamic> ? nivel['nome_nivel'] : badge['nivelNome'];

    return [
      badge['titulo'],
      badge['nome_badge'],
      areaNome,
      nivelNome,
    ].whereType<Object>().join(' ').toLowerCase();
  }

  bool _isEspecial(Map<String, dynamic> badge) {
    return badge['especial'] == true;
  }

  bool _isMinhaArea(Map<String, dynamic> badge) {
    return badge['minha_area'] == true || badge['minhaArea'] == true;
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      backgroundColor: AppCores.branco,
      appBar: AppBar(
        backgroundColor: AppCores.branco,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        centerTitle: false,
        titleSpacing: AppTamanhos.colocacao_titulo,
        title: Text(
          l10n.galeriaTitulo,
          style: const TextStyle(
            color: AppCores.fontes,
            fontSize: AppTamanhos.titulo,
          ),
        ),
        actions: const [TopBarActions()],
      ),
      body: AnimatedBuilder(
        animation: GaleriaController.instance,
        builder: (context, _) {
          final controller = GaleriaController.instance;

          if (controller.isLoading && controller.todosBadges.isEmpty) {
            return const Center(
              child: CircularProgressIndicator(color: AppCores.azulFundo),
            );
          }

          if (controller.errorMessage != null && controller.todosBadges.isEmpty) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: Text(
                  controller.errorMessage!,
                  style: const TextStyle(color: Colors.red, fontSize: 14.0),
                  textAlign: TextAlign.center,
                ),
              ),
            );
          }

          return RefreshIndicator(
            onRefresh: () async {
              await controller.carregarDados();
            },
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              child: Padding(
                padding: const EdgeInsets.all(AppTamanhos.margemEcra),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    BarraDeSelecao(
                      onSelectionChanged: (int index) {
                        setState(() {
                          _abaSelecionada = index;
                        });
                      },
                    ),
                    const SizedBox(height: AppTamanhos.gapBadgesPessoais),
                    _abaSelecionada == 1
                        ? Builder(
                            builder: (context) {
                              // 1. Get searched list of badges
                              final badges = _filtrarBadges(controller.todosBadges);

                              // 2. Compute dynamic counts based on search query
                              final int countTodos = badges.length;
                              final int countConcluidos = badges.where((b) => b['estado'] == 'concluidos' || b['estado'] == 'conquistados').length;
                              final int countExpirados = badges.where((b) => b['estado'] == 'expirados').length;
                              final int countRecusados = badges.where((b) => b['estado'] == 'recusados' || b['estado'] == 'recusado').length;
                              final int countPendentes = badges.where((b) => b['estado'] == 'pendentes').length;
                              final int countEmProgresso = badges.where((b) => b['estado'] == 'emProgresso').length;

                              final Map<String, int> filtros = {
                                'todos': countTodos,
                                'concluidos': countConcluidos,
                                'expirados': countExpirados,
                                'recusados': countRecusados,
                                'pendentes': countPendentes,
                                'emProgresso': countEmProgresso,
                              };

                              // 3. Filter by current selected chip
                              final filteredDisplay = badges.where((badge) {
                                if (_filtroSelecionado == 'todos') return true;
                                final estado = badge['estado']?.toString().toLowerCase();
                                if (_filtroSelecionado == 'concluidos') return estado == 'concluidos' || estado == 'conquistados';
                                if (_filtroSelecionado == 'expirados') return estado == 'expirados';
                                if (_filtroSelecionado == 'recusados') return estado == 'recusados' || estado == 'recusado';
                                if (_filtroSelecionado == 'pendentes') return estado == 'pendentes';
                                if (_filtroSelecionado == 'emProgresso') return estado == 'emprogresso';
                                return true;
                              }).toList();

                              final listaEspeciais =
                                  filteredDisplay.where(_isEspecial).toList();
                              final listaMinhaArea = filteredDisplay
                                  .where(
                                    (badge) =>
                                        !_isEspecial(badge) &&
                                        _isMinhaArea(badge),
                                  )
                                  .toList();
                              final listaOutrasAreas = filteredDisplay
                                  .where(
                                    (badge) =>
                                        !_isEspecial(badge) &&
                                        !_isMinhaArea(badge),
                                  )
                                  .toList();

                              return AbaTodosBadges(
                                listaEspeciais: listaEspeciais,
                                listaMinhaArea: listaMinhaArea,
                                listaOutrasAreas: listaOutrasAreas,
                                filtroSelecionado: _filtroSelecionado,
                                filtros: filtros,
                                onFilterChanged: (newFilter) {
                                  setState(() {
                                    _filtroSelecionado = newFilter;
                                  });
                                },
                                onSearchChanged: (value) {
                                  setState(() {
                                    _pesquisa = value;
                                  });
                                },
                                filterOptions: _filterOptions,
                                onFilterOptionsChanged: (newOptions) {
                                  setState(() {
                                    _filterOptions = newOptions;
                                  });
                                },
                              );
                            },
                          )
                        : AbaSugeridos(sugeridos: controller.sugeridosBadges),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

class BarraDeSelecao extends StatefulWidget {
  final ValueChanged<int> onSelectionChanged;

  const BarraDeSelecao({super.key, required this.onSelectionChanged});

  @override
  State<BarraDeSelecao> createState() => _BarraDeSelecaoState();
}

class _BarraDeSelecaoState extends State<BarraDeSelecao> {
  int _selectedIndex = 1;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Container(
      height: 48.0,
      padding: const EdgeInsets.all(5.0),
      decoration: BoxDecoration(
        color: AppCores.branco,
        borderRadius: BorderRadius.circular(AppBorders.pilulas.toDouble()),
        border: Border.all(
          color: AppCores.outline,
          width: 1.6,
        ),
      ),
      child: Row(
        children: [
          _buildSegment(0, l10n.sugeridos),
          _buildSegment(1, l10n.todosOsBadges),
        ],
      ),
    );
  }

  Widget _buildSegment(int index, String title) {
    final isSelected = _selectedIndex == index;

    return Expanded(
      child: GestureDetector(
        onTap: () {
          setState(() {
            _selectedIndex = index;
          });
          widget.onSelectionChanged(index);
        },
        child: Container(
          decoration: BoxDecoration(
            color: isSelected ? AppCores.azulFundo : Colors.transparent,
            borderRadius: BorderRadius.circular(AppBorders.padrao.toDouble()),
          ),
          alignment: Alignment.center,
          child: Text(
            title,
            style: TextStyle(
              color: isSelected ? AppCores.branco : AppCores.fontes,
              fontSize: 14.0,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      ),
    );
  }
}
