import 'package:flutter/material.dart';
import 'custom_filter_chip.dart';
import '../idiomas/app_localizations.dart';

class FilterChipsList extends StatelessWidget {
  final String filtroSelecionado;
  final Map<String, int> filtros;
  final ValueChanged<String> onFilterChanged;

  const FilterChipsList({
    super.key,
    required this.filtroSelecionado,
    required this.filtros,
    required this.onFilterChanged,
  });

  String _getTranslatedLabel(String key, AppLocalizations l10n) {
    switch (key) {
      case 'todos':
        return l10n.todos;
      case 'conquistados':
        return l10n.conquistados;
      case 'concluidos':
        return l10n.concluidos;
      case 'expirados':
        return l10n.expirados;
      case 'recusados':
        return l10n.recusados;
      case 'pendentes':
        return l10n.pendentes;
      case 'emProgresso':
        return l10n.emProgresso;
      default:
        return key;
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: filtros.entries.map((entry) {
          final isSelected = filtroSelecionado == entry.key;
          return Padding(
            padding: const EdgeInsets.only(right: 8.0),
            child: CustomFilterChip(
              label: _getTranslatedLabel(entry.key, l10n),
              count: entry.value,
              isSelected: isSelected,
              onTap: () => onFilterChanged(entry.key),
            ),
          );
        }).toList(),
      ),
    );
  }
}
