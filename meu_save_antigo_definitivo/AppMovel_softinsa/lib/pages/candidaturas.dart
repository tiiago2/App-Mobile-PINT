import 'package:flutter/material.dart';
import 'package:uicons/uicons.dart';
import '../controllers/candidaturas_controller.dart';
import '../idiomas/app_localizations.dart';
import '../variaveis/variaveis.dart';
import '../widgets/badge_card.dart';
import '../widgets/filter_chips_list.dart';
import '../widgets/searchbar_filter.dart';
import '../widgets/top_bar_actions.dart';

class CandidaturasScreen extends StatefulWidget {
  const CandidaturasScreen({super.key});

  @override
  State<CandidaturasScreen> createState() => _CandidaturasScreenState();
}

class _CandidaturasScreenState extends State<CandidaturasScreen> {
  String _filtroSelecionado = 'todos';
  String _pesquisa = '';
  FilterOptions _filterOptions = const FilterOptions();

  final CandidaturasController _controller = CandidaturasController.instance;

  @override
  void initState() {
    super.initState();
    _controller.carregar();
  }

  BadgeCardStatus _parseStatus(String statusStr) {
    final s = statusStr.toLowerCase();
    if (s == 'aceite' || s == 'aprovado' || s == 'conquistados') {
      return BadgeCardStatus.aprovado;
    }
    if (s == 'em_progresso' || s == 'emprogresso') {
      return BadgeCardStatus.emProgresso;
    }
    if (s == 'pendente' || s == 'submetida_pendente' || s == 'rascunho') {
      return BadgeCardStatus.pendente;
    }
    if (s == 'recusada' || s == 'recusado' || s == 'recusados') {
      return BadgeCardStatus.recusado;
    }
    if (s == 'expirado' || s == 'expirados') {
      return BadgeCardStatus.expirado;
    }
    return BadgeCardStatus.pendente;
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
          l10n.candidaturasTitulo,
          style: const TextStyle(
            color: AppCores.fontes,
            fontSize: AppTamanhos.titulo,
          ),
        ),
        actions: const [
          TopBarActions(),
        ],
      ),
      body: ListenableBuilder(
        listenable: _controller,
        builder: (context, _) {
          final rawList = _controller.candidaturas;

          final mappedBadges = rawList.map((raw) {
            final badgeInfo = raw['badge'] is Map<String, dynamic>
                ? raw['badge'] as Map<String, dynamic>
                : <String, dynamic>{};

            final title = raw['badge_titulo']?.toString() ??
                badgeInfo['nome_badge']?.toString() ??
                badgeInfo['titulo']?.toString() ??
                'Candidatura';

            final category = raw['badge_area']?.toString() ??
                badgeInfo['area_nome']?.toString() ??
                badgeInfo['categoria']?.toString() ??
                'Geral';

            final points = (raw['badge_pontos'] as int?) ??
                (badgeInfo['pontos_badge'] as int?) ??
                (badgeInfo['pontos'] as int?) ??
                0;

            final statusStr = raw['status']?.toString() ?? raw['estado_calculado']?.toString() ?? 'pendente';
            final cardStatus = _parseStatus(statusStr);

            DateTime? dateVal;
            final dataStr = raw['data_submissao']?.toString() ?? raw['data_obtencao']?.toString();
            if (dataStr != null) {
              dateVal = DateTime.tryParse(dataStr);
            }

            return {
              'title': title,
              'category': category,
              'points': points,
              'icon': UIcons.boldRounded.coffee,
              'avatarColor': const Color(0xFF39639C),
              'status': cardStatus,
              'date': dateVal,
              'raw': raw,
              'alertMessage': cardStatus == BadgeCardStatus.expirado ? l10n.badgeExpiradoAlert : null,
            };
          }).toList();

          // 1. Pesquisa
          var searchedBadges = mappedBadges.where((b) {
            final query = _pesquisa.trim().toLowerCase();
            if (query.isEmpty) return true;
            final title = b['title']?.toString().toLowerCase() ?? '';
            final category = b['category']?.toString().toLowerCase() ?? '';
            return title.contains(query) || category.contains(query);
          }).toList();

          // 2. Filtro de Abas
          List<Map<String, dynamic>> filteredBadges;
          if (_filtroSelecionado == 'todos') {
            filteredBadges = searchedBadges;
          } else {
            filteredBadges = searchedBadges.where((b) {
              final status = b['status'] as BadgeCardStatus;
              switch (_filtroSelecionado) {
                case 'aprovados':
                case 'conquistados':
                  return status == BadgeCardStatus.aprovado;
                case 'emProgresso':
                  return status == BadgeCardStatus.emProgresso;
                case 'pendentes':
                  return status == BadgeCardStatus.pendente;
                case 'recusados':
                  return status == BadgeCardStatus.recusado;
                case 'expirados':
                  return status == BadgeCardStatus.expirado;
                default:
                  return true;
              }
            }).toList();
          }

          final countsMap = <String, int>{
            'todos': mappedBadges.length,
            'pendentes': mappedBadges.where((b) => b['status'] == BadgeCardStatus.pendente).length,
            'emProgresso': mappedBadges.where((b) => b['status'] == BadgeCardStatus.emProgresso).length,
            'conquistados': mappedBadges.where((b) => b['status'] == BadgeCardStatus.aprovado).length,
            'recusados': mappedBadges.where((b) => b['status'] == BadgeCardStatus.recusado).length,
            'expirados': mappedBadges.where((b) => b['status'] == BadgeCardStatus.expirado).length,
          };

          return SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.all(AppTamanhos.margemEcra),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SearchBarFilter(
                    onChanged: (val) => setState(() => _pesquisa = val),
                    filterOptions: _filterOptions,
                    onFilterChanged: (opts) => setState(() => _filterOptions = opts),
                  ),
                  const SizedBox(height: 16.0),
                  FilterChipsList(
                    filtroSelecionado: _filtroSelecionado,
                    filtros: countsMap,
                    onFilterChanged: (filtro) {
                      setState(() {
                        _filtroSelecionado = filtro;
                      });
                    },
                  ),
                  const SizedBox(height: 16.0),
                  if (filteredBadges.isEmpty)
                    Container(
                      padding: const EdgeInsets.all(24.0),
                      decoration: BoxDecoration(
                        color: AppCores.fundo2,
                        borderRadius: BorderRadius.circular(AppBorders.padrao),
                        border: Border.all(color: AppCores.outline),
                      ),
                      child: Center(
                        child: Text(
                          'Nenhuma candidatura encontrada.',
                          style: TextStyle(
                            color: AppCores.fontes.withValues(alpha: 0.6),
                            fontSize: 14.0,
                          ),
                        ),
                      ),
                    )
                  else
                    ListView.separated(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: filteredBadges.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 12.0),
                      itemBuilder: (context, index) {
                        final b = filteredBadges[index];
                        return BadgeCard(
                          title: b['title'] as String,
                          category: b['category'] as String,
                          points: b['points'] as int,
                          icon: b['icon'] as IconData,
                          avatarColor: b['avatarColor'] as Color,
                          status: b['status'] as BadgeCardStatus,
                          date: b['date'] as DateTime?,
                          progressPercentage: b['progressPercentage'] as int?,
                          alertMessage: b['alertMessage'] as String?,
                        );
                      },
                    ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}