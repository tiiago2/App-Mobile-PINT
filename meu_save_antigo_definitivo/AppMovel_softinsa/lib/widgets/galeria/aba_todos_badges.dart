import 'package:flutter/material.dart';
import '../searchbar_filter.dart';
import '../filter_chips_list.dart';
import '../../variaveis/variaveis.dart';
import '../../idiomas/app_localizations.dart';
import 'divisao_especiais.dart';
import 'divisao_minha_area.dart';
import 'divisao_outras_areas.dart';
import 'badge_item_com_estado_wrapper.dart';

class AbaTodosBadges extends StatelessWidget {
  final List<Map<String, dynamic>> listaEspeciais;
  final List<Map<String, dynamic>> listaMinhaArea;
  final List<Map<String, dynamic>> listaOutrasAreas;
  final ValueChanged<String>? onSearchChanged;
  final String filtroSelecionado;
  final Map<String, int> filtros;
  final ValueChanged<String> onFilterChanged;
  final FilterOptions? filterOptions;
  final ValueChanged<FilterOptions>? onFilterOptionsChanged;

  const AbaTodosBadges({
    super.key,
    required this.listaEspeciais,
    required this.listaMinhaArea,
    required this.listaOutrasAreas,
    this.onSearchChanged,
    required this.filtroSelecionado,
    required this.filtros,
    required this.onFilterChanged,
    this.filterOptions,
    this.onFilterOptionsChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SearchBarFilter(
          hintText: AppLocalizations.of(context)?.pesquisarBadge ?? 'Pesquisar Badge...',
          onChanged: onSearchChanged,
          filterOptions: filterOptions,
          onFilterChanged: onFilterOptionsChanged,
        ),
        const SizedBox(height: AppTamanhos.espacamentoIcones),
        FilterChipsList(
          filtroSelecionado: filtroSelecionado,
          filtros: filtros,
          onFilterChanged: onFilterChanged,
        ),
        const SizedBox(height: AppTamanhos.gapBadgesPessoais),
        if (listaEspeciais.isNotEmpty) ...[
          DivisaoEspeciais(),
          const SizedBox(height: AppTamanhos.gapBadgesPessoais),
          GaleriaBadgesComEstado(badges: listaEspeciais),
          const SizedBox(height: AppTamanhos.gapBadgesPessoais),
        ],
        if (listaMinhaArea.isNotEmpty) ...[
          DivisaoMinhaArea(),
          const SizedBox(height: AppTamanhos.gapBadgesPessoais),
          GaleriaBadgesComEstado(badges: listaMinhaArea),
          const SizedBox(height: AppTamanhos.gapBadgesPessoais),
        ],
        if (listaOutrasAreas.isNotEmpty) ...[
          DivisaoOutrasAreas(),
          const SizedBox(height: AppTamanhos.gapBadgesPessoais),
          GaleriaBadgesComEstado(badges: listaOutrasAreas),
        ],
      ],
    );
  }
}
