import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:uicons/uicons.dart';
import '../variaveis/variaveis.dart';
import '../widgets/top_bar_actions.dart';
import '../widgets/searchbar_filter.dart';
import '../widgets/filter_chips_list.dart';
import '../widgets/badge_card.dart';
import '../idiomas/app_localizations.dart';
import '../controllers/auth_controller.dart';
import '../database/daos/submissao_dao.dart';
import '../database/daos/outros_users_dao.dart';
import '../database/sync_helpers.dart';

class CandidaturasScreen extends StatefulWidget {
  const CandidaturasScreen({super.key});

  @override
  State<CandidaturasScreen> createState() => _CandidaturasScreenState();
}

class _CandidaturasScreenState extends State<CandidaturasScreen> {
  String _filtroSelecionado = 'todos';
  String _pesquisa = '';
  FilterOptions _filterOptions = const FilterOptions();

  List<Map<String, dynamic>> _candidaturas = [];
  int _totalPontos = 0;
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _carregarDados();
  }

  Future<void> _carregarDados() async {
    final user = AuthController.instance.currentUser;
    final userId = intOrNull(user?['id'] ?? user?['user_id'] ?? user?['id_utilizador']);

    if (userId == null) {
      setState(() {
        _errorMessage = 'Utilizador não autenticado.';
        _isLoading = false;
      });
      return;
    }

    try {
      // 1. Obter total de pontos do utilizador logado
      final outroUser = await OutrosUsersDao.instance.getUser(userId);
      final totalPontos = intOrNull(outroUser?['pontos_totais']) ?? 0;

      // 2. Obter todas as submissões reais do utilizador
      final rows = await SubmissoesDao.instance.lerSubmissoesDoUtilizador(userId);

      final List<Map<String, dynamic>> mapped = [];
      for (final row in rows) {
        final statusStr = (row['status']?.toString() ?? '').toLowerCase().trim();
        BadgeCardStatus cardStatus = BadgeCardStatus.pendente;
        int? progress;

        if (statusStr == 'draft' || statusStr == 'rascunho' || statusStr == 'em_progresso' || statusStr == 'emprogresso') {
          cardStatus = BadgeCardStatus.emProgresso;
          progress = 0;
          try {
            final jsonStr = row['submissao_json'] as String?;
            if (jsonStr != null && jsonStr.isNotEmpty) {
              final Map<String, dynamic> decoded = jsonDecode(jsonStr);
              progress = intOrNull(decoded['progressPercentage']) ?? 0;
            }
          } catch (_) {}
          if (progress == 0) {
            progress = 45; 
          }
        } else if (statusStr == 'rejeitado' || statusStr == 'rejeitada' || statusStr == 'reprovado' || statusStr == 'reprovada' || statusStr == 'recusado' || statusStr == 'recusada' || statusStr == 'rejected') {
          cardStatus = BadgeCardStatus.recusado;
        } else if (statusStr == 'approved' || statusStr == 'aprovado' || statusStr == 'conquistado' || statusStr == 'aceite') {
          cardStatus = BadgeCardStatus.aprovado;
        } else if (statusStr == 'expirado' || statusStr == 'expirados') {
          cardStatus = BadgeCardStatus.expirado;
        }

        final dataCriacaoStr = row['data_criacao']?.toString() ?? '';
        final dataSubmissaoStr = row['data_submissao']?.toString() ?? '';
        DateTime? dateObj;
        try {
          if (dataSubmissaoStr.isNotEmpty) {
            dateObj = DateTime.parse(dataSubmissaoStr);
          } else if (dataCriacaoStr.isNotEmpty) {
            dateObj = DateTime.parse(dataCriacaoStr);
          }
        } catch (_) {}

        final colors = [
          const Color(0xFF39639C), // Azul
          const Color(0xFF10B981), // Verde
          const Color(0xFF8B5CF6), // Roxo
          const Color(0xFFF97316), // Laranja
          const Color(0xFF06B6D4), // Ciano
        ];
        final badgeId = intOrNull(row['id_badge']) ?? 0;
        final avatarColor = colors[badgeId % colors.length];

        mapped.add({
          'id': badgeId,
          'title': row['badge_titulo'] ?? 'Badge sem título',
          'category': row['badge_area'] ?? 'Geral',
          'points': intOrNull(row['badge_pontos']) ?? 0,
          'icon': UIcons.boldRounded.coffee,
          'avatarColor': avatarColor,
          'status': cardStatus,
          'date': dateObj,
          'progressPercentage': progress,
          'alertMessage': row['feedback'],
          'imagem': row['badge_imagem'],
          'especial': row['especial'] == 1 || row['especial'] == true,
          'nivelId': row['nivelId'],
          'nivelNome': row['nivelNome'],
          'serviceLineId': row['serviceLineId'],
          'serviceLineNome': row['serviceLineNome'],
          'learningPathId': row['learningPathId'],
          'learningPathNome': row['learningPathNome'],
        });
      }

      setState(() {
        _candidaturas = mapped;
        _totalPontos = totalPontos;
        _isLoading = false;
        _errorMessage = null;
      });
    } catch (e) {
      setState(() {
        _errorMessage = 'Erro ao carregar candidaturas: $e';
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    if (_isLoading) {
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
            l10n.candidaturasTitulo,
            style: const TextStyle(color: AppCores.fontes, fontSize: AppTamanhos.titulo),
          ),
        ),
        body: const Center(
          child: CircularProgressIndicator(
            color: AppCores.azulFundo,
          ),
        ),
      );
    }

    for (final badge in _candidaturas) {
      if (badge['status'] == BadgeCardStatus.expirado &&
          (badge['alertMessage'] == null || badge['alertMessage'].toString().isEmpty)) {
        badge['alertMessage'] = l10n.badgeExpiradoAlert;
      }
    }

    // 1. Filter by search query
    var searchedBadges = _candidaturas.where((badge) {
      final query = _pesquisa.trim().toLowerCase();
      if (query.isEmpty) return true;
      final title = badge['title']?.toString().toLowerCase() ?? '';
      final category = badge['category']?.toString().toLowerCase() ?? '';
      return title.contains(query) || category.contains(query);
    }).toList();

    String removerAcentos(String text) {
      const comAcentos = 'ÀÁÂÃÄÅÆÇÈÉÊËÌÍÎÏÐÑÒÓÔÕÖØÙÚÛÜÝÞßàáâãäåæçèéêëìíîïðñòóôõöøùúûüýþÿ';
      const semAcentos = 'AAAAAAACEEEEIIIIDNOOOOOOUUUUYPsBaaaaaaaceeeeiiiidnoooooouuuuyby';
      var out = text;
      for (var i = 0; i < comAcentos.length; i++) {
        out = out.replaceAll(comAcentos[i], semAcentos[i]);
      }
      return out;
    }

    // Apply Level Filter
    if (_filterOptions.nivel != 'todos') {
      final String lvl = _filterOptions.nivel;
      searchedBadges = searchedBadges.where((b) {
        final nivelId = int.tryParse(b['nivelId']?.toString() ?? '');
        int? lvlFilterId = int.tryParse(lvl);
        if (lvlFilterId == null) {
          if (lvl == 'basico') lvlFilterId = 1;
          if (lvl == 'intermedio') lvlFilterId = 2;
          if (lvl == 'senior') lvlFilterId = 3;
          if (lvl == 'especialista') lvlFilterId = 4;
          if (lvl == 'lider') lvlFilterId = 5;
        }
        if (nivelId != null && lvlFilterId != null) {
          return nivelId == lvlFilterId;
        }
        final nivel = b['nivel'];
        final nivelNome = (nivel is Map<String, dynamic> ? nivel['nome_nivel'] : b['nivelNome'] ?? b['nivel'] ?? '').toString().toLowerCase();
        final title = (b['titulo'] ?? b['nome_badge'] ?? b['title'] ?? '').toString().toLowerCase();
        if (lvl == 'basico') return nivelNome.contains('básico') || nivelNome.contains('basico') || title.contains('básico') || title.contains('basico') || title.contains('practitioner');
        if (lvl == 'intermedio') return nivelNome.contains('intermédio') || nivelNome.contains('intermedio') || title.contains('intermédio') || title.contains('intermedio') || title.contains('master');
        if (lvl == 'senior') return nivelNome.contains('sénior') || nivelNome.contains('senior') || title.contains('sénior') || title.contains('senior') || title.contains('pro') || title.contains('avançado') || title.contains('avancado');
        if (lvl == 'especialista') return nivelNome.contains('especialista') || title.contains('especialista');
        if (lvl == 'lider') return nivelNome.contains('líder') || nivelNome.contains('lider') || title.contains('líder') || title.contains('lider');
        return false;
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
        final slId = int.tryParse(b['serviceLineId']?.toString() ?? '');
        int? slFilterId = int.tryParse(sl);
        if (slFilterId == null) {
          if (sl == 'cloud') slFilterId = 1;
          if (sl == 'appdev') slFilterId = 2;
          if (sl == 'enterprise') slFilterId = 3;
          if (sl == 'security') slFilterId = 4;
        }
        if (slId != null && slFilterId != null) {
          return slId == slFilterId;
        }
        final title = (b['title'] ?? b['titulo'] ?? b['nome'] ?? b['nome_badge'] ?? '').toString().toLowerCase();
        final area = (b['area'] ?? b['areaNome'] ?? b['category'] ?? b['categoria'] ?? '').toString().toLowerCase();
        final slNome = (b['serviceLineNome'] ?? '').toString().toLowerCase();
        if (sl == 'cloud' || sl == '1') return slNome.contains('cloud') || area.contains('cloud') || title.contains('cloud') || title.contains('aws');
        if (sl == 'appdev' || sl == '2') return slNome.contains('app') || slNome.contains('dev') || area.contains('dev') || area.contains('low') || area.contains('design') || title.contains('flutter') || title.contains('java') || title.contains('scrum') || title.contains('outsystems');
        if (sl == 'enterprise' || sl == '3') return slNome.contains('enterprise') || title.contains('sap') || title.contains('salesforce') || title.contains('oracle');
        if (sl == 'security' || sl == '4') return slNome.contains('security') || slNome.contains('segurança') || slNome.contains('cyber') || area.contains('security') || area.contains('segurança') || area.contains('cyber') || title.contains('security') || title.contains('segurança') || title.contains('cyber');
        return false;
      }).toList();
    }

    // Apply Learning Path Filter
    if (_filterOptions.learningPath != 'todos') {
      final String lp = _filterOptions.learningPath;
      searchedBadges = searchedBadges.where((b) {
        final lpId = int.tryParse(b['learningPathId']?.toString() ?? '');
        int? lpFilterId = int.tryParse(lp);
        if (lpFilterId == null) {
          if (lp == 'digital_innovation') lpFilterId = 1;
          if (lp == 'cloud_solutions') lpFilterId = 2;
          if (lp == 'lowcode_agile') lpFilterId = 3;
          if (lp == 'cybersecurity') lpFilterId = 4;
          if (lp == 'devops_agile') lpFilterId = 5;
        }
        if (lpId != null && lpFilterId != null) {
          return lpId == lpFilterId;
        }
        final title = (b['title'] ?? b['titulo'] ?? b['nome'] ?? b['nome_badge'] ?? '').toString().toLowerCase();
        final areaVal = (b['area'] ?? b['areaNome'] ?? b['category'] ?? b['categoria'] ?? '').toString().toLowerCase();
        final lpNome = (b['learningPathNome'] ?? '').toString().toLowerCase();
        if (lp == 'digital_innovation' || lp == '1') return lpNome.contains('digital') || lpNome.contains('innovation') || title.contains('digital') || title.contains('innovation');
        if (lp == 'cloud_solutions' || lp == '2') return lpNome.contains('cloud') || areaVal.contains('cloud') || title.contains('cloud') || title.contains('aws');
        if (lp == 'lowcode_agile' || lp == '3') return lpNome.contains('low') || lpNome.contains('agile') || areaVal.contains('low') || title.contains('low') || title.contains('outsystems') || title.contains('scrum');
        if (lp == 'cybersecurity' || lp == '4') return lpNome.contains('security') || lpNome.contains('segurança') || lpNome.contains('cyber') || areaVal.contains('security') || areaVal.contains('segurança') || areaVal.contains('cyber') || title.contains('security') || title.contains('segurança') || title.contains('cyber');
        if (lp == 'devops_agile' || lp == '5') return lpNome.contains('devops') || lpNome.contains('agile') || areaVal.contains('dev') || title.contains('devops') || title.contains('agile');
        return false;
      }).toList();
    }

    // Apply Sorting
    searchedBadges.sort((a, b) {
      final rawA = (a['titulo'] ?? a['nome_badge'] ?? a['title'] ?? '').toString();
      final rawB = (b['titulo'] ?? b['nome_badge'] ?? b['title'] ?? '').toString();
      final nameA = removerAcentos(rawA).toLowerCase().trim();
      final nameB = removerAcentos(rawB).toLowerCase().trim();
      final ptsA = int.tryParse((a['pontos'] ?? a['points'] ?? a['pontos_badge'] ?? '0').toString()) ?? 0;
      final ptsB = int.tryParse((b['pontos'] ?? b['points'] ?? b['pontos_badge'] ?? '0').toString()) ?? 0;

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
                        '$_totalPontos ${l10n.pts}',
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
              child: filteredBadges.isEmpty
                  ? Center(
                      child: Padding(
                        padding: const EdgeInsets.all(32.0),
                        child: Text(
                          _errorMessage ?? 'Nenhuma candidatura encontrada.',
                          style: TextStyle(
                            color: AppCores.fontes.withOpacity(0.5),
                            fontSize: 14.0,
                          ),
                        ),
                      ),
                    )
                  : ListView.separated(
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
                          imagem: badge['imagem'],
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