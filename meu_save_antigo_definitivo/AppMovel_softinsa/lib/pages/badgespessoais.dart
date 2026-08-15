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
import '../controllers/auth_controller.dart';
import '../database/daos/badges_dao.dart';
import '../database/daos/perfil_dao.dart';
import '../database/daos/outros_users_dao.dart';
import '../database/sync_helpers.dart';

class BadgesPessoaisScreen extends StatefulWidget {
  const BadgesPessoaisScreen({super.key});

  @override
  State<BadgesPessoaisScreen> createState() => _BadgesPessoaisScreen();
}

class _BadgesPessoaisScreen extends State<BadgesPessoaisScreen> {
  String _pesquisa = '';
  FilterOptions _filterOptions = const FilterOptions();

  List<Map<String, dynamic>> _badges = [];
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
      // 1. Obter area_id do perfil do utilizador
      final perfil = await PerfilDao.instance.lerPerfilComArea(userId);
      final userAreaId = intOrNull(perfil?['id_area']) ?? 0;

      // 2. Obter pontuação total da tabela outros_users
      final outroUser = await OutrosUsersDao.instance.getUser(userId);
      final totalPontos = intOrNull(outroUser?['pontos_totais']) ?? 0;

      // 3. Obter todos os badges com estados calculados
      final todosBadges = await BadgesDao.instance.obterTodosBadgesParaGaleria(
        userId: userId,
        userAreaId: userAreaId,
      );

      // 4. Filtrar os concluídos (estado == 'conquistados')
      final realBadges = todosBadges
          .where((b) => b['estado'] == 'conquistados')
          .map((b) => {
                ...b,
                'id': b['id_badge'],
                'titulo': b['nome_badge'] ?? '',
                'area': b['areaNome'] ?? 'Sem Área',
                'especial': b['especial'] == true ? '1' : '0',
              })
          .toList();

      setState(() {
        _badges = realBadges;
        _totalPontos = totalPontos;
        _isLoading = false;
        _errorMessage = null;
      });
    } catch (e) {
      setState(() {
        _errorMessage = 'Erro ao carregar os seus badges: $e';
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    String removerAcentos(String text) {
      const comAcentos = 'ÀÁÂÃÄÅÆÇÈÉÊËÌÍÎÏÐÑÒÓÔÕÖØÙÚÛÜÝÞßàáâãäåæçèéêëìíîïðñòóôõöøùúûüýþÿ';
      const semAcentos = 'AAAAAAACEEEEIIIIDNOOOOOOUUUUYPsBaaaaaaaceeeeiiiidnoooooouuuuyby';
      var out = text;
      for (var i = 0; i < comAcentos.length; i++) {
        out = out.replaceAll(comAcentos[i], semAcentos[i]);
      }
      return out;
    }

    // Apply search filter
    var filteredBadges = _badges.where((badge) {
      final query = _pesquisa.trim().toLowerCase();
      if (query.isEmpty) return true;
      final title = (badge['nome_badge'] ?? badge['titulo'] ?? badge['title'] ?? '').toString().toLowerCase();
      final area = (badge['areaNome'] ?? badge['area'] ?? badge['category'] ?? '').toString().toLowerCase();
      return title.contains(query) || area.contains(query);
    }).toList();

    // Apply Level Filter
    if (_filterOptions.nivel != 'todos') {
      final String lvl = _filterOptions.nivel;
      filteredBadges = filteredBadges.where((b) {
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
      filteredBadges = filteredBadges.where((b) {
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
    filteredBadges.sort((a, b) {
      final rawA = (a['titulo'] ?? a['nome_badge'] ?? a['title'] ?? '').toString();
      final rawB = (b['titulo'] ?? b['nome_badge'] ?? b['title'] ?? '').toString();
      final nameA = removerAcentos(rawA).toLowerCase().trim();
      final nameB = removerAcentos(rawB).toLowerCase().trim();
      final ptsA = int.tryParse((a['pontos'] ?? a['points'] ?? '0').toString()) ?? 0;
      final ptsB = int.tryParse((b['pontos'] ?? b['points'] ?? '0').toString()) ?? 0;

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

    final listaEspeciais = filteredBadges.where((b) => b['especial'] == '1' || b['especial'] == true).toList();
    final listaMinhaArea = filteredBadges.where((b) => b['especial'] != '1' && b['especial'] != true && (b['minha_area'] == true || b['minhaArea'] == true)).toList();
    final listaOutrasAreas = filteredBadges.where((b) => b['especial'] != '1' && b['especial'] != true && b['minha_area'] != true && b['minhaArea'] != true).toList();

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
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(color: AppCores.azulFundo),
            )
          : _errorMessage != null
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24.0),
                    child: Text(
                      _errorMessage!,
                      style: const TextStyle(color: Colors.red, fontSize: 14.0),
                      textAlign: TextAlign.center,
                    ),
                  ),
                )
              : RefreshIndicator(
                  onRefresh: _carregarDados,
                  child: SingleChildScrollView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    child: Padding(
                      padding: const EdgeInsets.all(AppTamanhos.margemEcra),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          CartaoTotalPontos(pontos: _totalPontos),
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
                          if (listaEspeciais.isEmpty && listaMinhaArea.isEmpty && listaOutrasAreas.isEmpty)
                            Center(
                              child: Padding(
                                padding: const EdgeInsets.all(40.0),
                                child: Text(
                                  l10n?.semBadgesSeccao ?? 'Nenhum badge encontrado.',
                                  style: const TextStyle(color: AppCores.fontes, fontSize: 14.0),
                                ),
                              ),
                            ),
                        ],
                      ),
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