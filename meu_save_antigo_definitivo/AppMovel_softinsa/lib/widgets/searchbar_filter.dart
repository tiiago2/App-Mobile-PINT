import 'package:flutter/material.dart';
import 'package:uicons/uicons.dart';
import '../variaveis/variaveis.dart';
import '../idiomas/app_localizations.dart';

class FilterOptions {
  final String ordenarPor; // 'nome_asc', 'nome_desc', 'pontos_asc', 'pontos_desc'
  final String nivel; // 'todos', 'basico', 'intermedio', 'senior', 'especialista', 'lider'
  final String tipo; // 'todos', 'especial', 'normal'
  final String serviceLine; // 'todos', 'cloud', 'appdev', 'enterprise', 'security'
  final String learningPath; // 'todos', 'digital_innovation', 'cloud_solutions', 'lowcode_agile', 'cybersecurity', 'devops_agile'

  const FilterOptions({
    this.ordenarPor = 'nome_asc',
    this.nivel = 'todos',
    this.tipo = 'todos',
    this.serviceLine = 'todos',
    this.learningPath = 'todos',
  });

  FilterOptions copyWith({
    String? ordenarPor,
    String? nivel,
    String? tipo,
    String? serviceLine,
    String? learningPath,
  }) {
    return FilterOptions(
      ordenarPor: ordenarPor ?? this.ordenarPor,
      nivel: nivel ?? this.nivel,
      tipo: tipo ?? this.tipo,
      serviceLine: serviceLine ?? this.serviceLine,
      learningPath: learningPath ?? this.learningPath,
    );
  }
}

class SearchBarFilter extends StatelessWidget {
  final String? hintText;
  final VoidCallback? onFilterPressed;
  final ValueChanged<String>? onChanged;
  final FilterOptions? filterOptions;
  final ValueChanged<FilterOptions>? onFilterChanged;

  const SearchBarFilter({
    super.key,
    this.hintText,
    this.onFilterPressed,
    this.onChanged,
    this.filterOptions,
    this.onFilterChanged,
  });

  void _showFilterBottomSheet(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final current = filterOptions ?? const FilterOptions();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      enableDrag: true,
      backgroundColor: AppCores.branco,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24.0)),
      ),
      builder: (BuildContext context) {
        String selOrder = current.ordenarPor;
        String selNivel = current.nivel;
        String selTipo = current.tipo;
        String selServiceLine = current.serviceLine;
        String selLearningPath = current.learningPath;

        return StatefulBuilder(
          builder: (BuildContext context, StateSetter setModalState) {
            Widget buildChoiceChip({
              required String label,
              required bool selected,
              required VoidCallback onSelected,
            }) {
              return ChoiceChip(
                label: Text(
                  label,
                  style: TextStyle(
                    color: selected ? AppCores.branco : AppCores.fontes,
                    fontSize: 13.0,
                    fontWeight: selected ? FontWeight.bold : FontWeight.normal,
                  ),
                ),
                selected: selected,
                onSelected: (_) => onSelected(),
                selectedColor: AppCores.azulFundo,
                backgroundColor: AppCores.fundo2,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(AppBorders.pilulas),
                  side: BorderSide(
                    color: selected ? AppCores.azulFundo : AppCores.outline,
                    width: 1.0,
                  ),
                ),
                showCheckmark: false,
              );
            }

            return SingleChildScrollView(
              child: Padding(
                padding: EdgeInsets.only(
                  left: 20.0,
                  right: 20.0,
                  top: 16.0,
                  bottom: 16.0 + MediaQuery.of(context).viewInsets.bottom,
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Drag handle
                    Center(
                      child: Container(
                        width: 40,
                        height: 5,
                        decoration: BoxDecoration(
                          color: AppCores.outline,
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                    // Title
                    Text(
                      l10n?.filtrar ?? 'Filtrar',
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: AppCores.fontes,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 24),

                    // ================= ORDENAR SECTION =================
                    Row(
                      children: [
                        Icon(UIcons.boldRounded.sort, size: 16, color: AppCores.fontes),
                        const SizedBox(width: 8),
                        Text(
                          (l10n?.ordenarPor ?? 'Ordenar por').toUpperCase(),
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: AppCores.fontes,
                            letterSpacing: 0.8,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Wrap(
                      spacing: 8.0,
                      runSpacing: 4.0,
                      children: [
                        buildChoiceChip(
                          label: l10n?.ordenarNomeAsc ?? 'Nome (A-Z)',
                          selected: selOrder == 'nome_asc',
                          onSelected: () => setModalState(() => selOrder = 'nome_asc'),
                        ),
                        buildChoiceChip(
                          label: l10n?.ordenarNomeDesc ?? 'Nome (Z-A)',
                          selected: selOrder == 'nome_desc',
                          onSelected: () => setModalState(() => selOrder = 'nome_desc'),
                        ),
                        buildChoiceChip(
                          label: l10n?.ordenarPontosAsc ?? 'Pontos (Menor)',
                          selected: selOrder == 'pontos_asc',
                          onSelected: () => setModalState(() => selOrder = 'pontos_asc'),
                        ),
                        buildChoiceChip(
                          label: l10n?.ordenarPontosDesc ?? 'Pontos (Maior)',
                          selected: selOrder == 'pontos_desc',
                          onSelected: () => setModalState(() => selOrder = 'pontos_desc'),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                    const Divider(color: AppCores.outline, thickness: 1.0),
                    const SizedBox(height: 16),

                    // ================= FILTRAR SECTION =================
                    Row(
                      children: [
                        Icon(UIcons.boldRounded.filter, size: 16, color: AppCores.fontes),
                        const SizedBox(width: 8),
                        Text(
                          (l10n?.filtrar ?? 'Filtrar').toUpperCase(),
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: AppCores.fontes,
                            letterSpacing: 0.8,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),

                    // 2. Level Section
                    Text(
                      l10n?.nivel ?? 'Nível',
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: AppCores.fontes,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8.0,
                      runSpacing: 4.0,
                      children: [
                        buildChoiceChip(
                          label: l10n?.todos ?? 'Todos',
                          selected: selNivel == 'todos',
                          onSelected: () => setModalState(() => selNivel = 'todos'),
                        ),
                        buildChoiceChip(
                          label: l10n?.basico ?? 'Básico',
                          selected: selNivel == 'basico',
                          onSelected: () => setModalState(() => selNivel = 'basico'),
                        ),
                        buildChoiceChip(
                          label: l10n?.intermedio ?? 'Intermédio',
                          selected: selNivel == 'intermedio',
                          onSelected: () => setModalState(() => selNivel = 'intermedio'),
                        ),
                        buildChoiceChip(
                          label: l10n?.senior ?? 'Sénior',
                          selected: selNivel == 'senior',
                          onSelected: () => setModalState(() => selNivel = 'senior'),
                        ),
                        buildChoiceChip(
                          label: l10n?.especialista ?? 'Especialista',
                          selected: selNivel == 'especialista',
                          onSelected: () => setModalState(() => selNivel = 'especialista'),
                        ),
                        buildChoiceChip(
                          label: l10n?.lider ?? 'Líder',
                          selected: selNivel == 'lider',
                          onSelected: () => setModalState(() => selNivel = 'lider'),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),

                    // 3. Type Section
                    Text(
                      l10n?.tipo ?? 'Tipo',
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: AppCores.fontes,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8.0,
                      runSpacing: 4.0,
                      children: [
                        buildChoiceChip(
                          label: l10n?.todos ?? 'Todos',
                          selected: selTipo == 'todos',
                          onSelected: () => setModalState(() => selTipo = 'todos'),
                        ),
                        buildChoiceChip(
                          label: l10n?.especial ?? 'Especial',
                          selected: selTipo == 'especial',
                          onSelected: () => setModalState(() => selTipo = 'especial'),
                        ),
                        buildChoiceChip(
                          label: l10n?.normal ?? 'Normal',
                          selected: selTipo == 'normal',
                          onSelected: () => setModalState(() => selTipo = 'normal'),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),

                    // 4. Service Line Dropdown
                    DropdownButtonFormField<String>(
                      initialValue: selServiceLine,
                      dropdownColor: AppCores.branco,
                      icon: Icon(UIcons.boldRounded.angle_small_down, size: 18, color: AppCores.fontes),
                      decoration: InputDecoration(
                        labelText: l10n?.serviceLineLabel ?? 'Service Line',
                        labelStyle: const TextStyle(color: AppCores.fontes, fontSize: 13.0, fontWeight: FontWeight.bold),
                        filled: true,
                        fillColor: AppCores.fundo2,
                        contentPadding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(AppBorders.padrao),
                          borderSide: const BorderSide(color: AppCores.outline),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(AppBorders.padrao),
                          borderSide: const BorderSide(color: AppCores.outline),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(AppBorders.padrao),
                          borderSide: const BorderSide(color: AppCores.azulFundo, width: 1.5),
                        ),
                      ),
                      style: const TextStyle(color: AppCores.fontes, fontSize: 14.0),
                      items: [
                        DropdownMenuItem(value: 'todos', child: Text(l10n?.todos ?? 'Todos')),
                        DropdownMenuItem(value: 'cloud', child: Text(l10n?.cloudServices ?? 'Cloud Services')),
                        DropdownMenuItem(value: 'appdev', child: Text(l10n?.appDev ?? 'Application Development')),
                        DropdownMenuItem(value: 'enterprise', child: Text(l10n?.enterpriseSolutions ?? 'Enterprise Solutions')),
                        DropdownMenuItem(value: 'security', child: Text(l10n?.securityServices ?? 'Security Services')),
                      ],
                      onChanged: (val) {
                        if (val != null) {
                          setModalState(() {
                            selServiceLine = val;
                          });
                        }
                      },
                    ),
                    const SizedBox(height: 16),

                    // 5. Learning Path Dropdown
                    DropdownButtonFormField<String>(
                      initialValue: selLearningPath,
                      dropdownColor: AppCores.branco,
                      icon: Icon(UIcons.boldRounded.angle_small_down, size: 18, color: AppCores.fontes),
                      decoration: InputDecoration(
                        labelText: l10n?.learningPathLabel ?? 'Learning Path',
                        labelStyle: const TextStyle(color: AppCores.fontes, fontSize: 13.0, fontWeight: FontWeight.bold),
                        filled: true,
                        fillColor: AppCores.fundo2,
                        contentPadding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(AppBorders.padrao),
                          borderSide: const BorderSide(color: AppCores.outline),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(AppBorders.padrao),
                          borderSide: const BorderSide(color: AppCores.outline),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(AppBorders.padrao),
                          borderSide: const BorderSide(color: AppCores.azulFundo, width: 1.5),
                        ),
                      ),
                      style: const TextStyle(color: AppCores.fontes, fontSize: 14.0),
                      items: [
                        DropdownMenuItem(value: 'todos', child: Text(l10n?.todos ?? 'Todos')),
                        DropdownMenuItem(value: 'digital_innovation', child: Text(l10n?.digitalInnovation ?? 'Digital Innovation')),
                        DropdownMenuItem(value: 'cloud_solutions', child: Text(l10n?.cloudSolutions ?? 'Cloud Solutions')),
                        DropdownMenuItem(value: 'lowcode_agile', child: Text(l10n?.lowCodeDev ?? 'Low Code Development')),
                        DropdownMenuItem(value: 'cybersecurity', child: Text(l10n?.cyberSecurity ?? 'Cyber Security')),
                        DropdownMenuItem(value: 'devops_agile', child: Text(l10n?.devOpsAgile ?? 'DevOps & Agile')),
                      ],
                      onChanged: (val) {
                        if (val != null) {
                          setModalState(() {
                            selLearningPath = val;
                          });
                        }
                      },
                    ),
                    const SizedBox(height: 28),

                    // Actions
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton(
                            onPressed: () => Navigator.pop(context),
                            style: OutlinedButton.styleFrom(
                              side: const BorderSide(color: AppCores.outline, width: 1.6),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(AppBorders.padrao),
                              ),
                            ),
                            child: Text(
                              l10n?.cancelar ?? 'Cancelar',
                              style: const TextStyle(color: AppCores.fontes),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: ElevatedButton(
                            onPressed: () {
                              Navigator.pop(context);
                              if (onFilterChanged != null) {
                                onFilterChanged!(
                                  FilterOptions(
                                    ordenarPor: selOrder,
                                    nivel: selNivel,
                                    tipo: selTipo,
                                    serviceLine: selServiceLine,
                                    learningPath: selLearningPath,
                                  ),
                                );
                              }
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppCores.azulFundo,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(AppBorders.padrao),
                              ),
                            ),
                            child: Text(
                              l10n?.confirmar ?? 'Confirmar',
                              style: const TextStyle(color: AppCores.branco, fontWeight: FontWeight.bold),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final defaultHint = AppLocalizations.of(context)?.pesquisar ?? 'Pesquisar...';

    return Row(
      children: [
        Expanded(
          child: Container(
            height: 44,
            decoration: BoxDecoration(
              color: AppCores.branco,
              borderRadius: BorderRadius.circular(AppBorders.padrao),
              border: Border.all(
                color: AppCores.outline,
                width: 1.6,
              ),
            ),
            child: Row(
              children: [
                const SizedBox(width: 16),
                Icon(
                  UIcons.boldRounded.search,
                  color: AppCores.fontes,
                  size: AppTamanhos.iconeSearchbarFilter,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: TextField(
                    onChanged: onChanged,
                    style: const TextStyle(
                      color: AppCores.fontes,
                      fontSize: 16,
                    ),
                    decoration: InputDecoration(
                      hintText: hintText ?? defaultHint,
                      hintStyle: TextStyle(
                        color: AppCores.fontes.withOpacity(0.5),
                        fontSize: 16,
                      ),
                      border: InputBorder.none,
                      isDense: true,
                      contentPadding: EdgeInsets.zero,
                     ),
                  ),
                ),
                const SizedBox(width: 16),
              ],
            ),
          ),
        ),
        const SizedBox(width: 12),
        InkWell(
          onTap: () {
            if (onFilterPressed != null) {
              onFilterPressed!();
            } else {
              _showFilterBottomSheet(context);
            }
          },
          borderRadius: BorderRadius.circular(AppBorders.padrao),
          child: Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: const Color(0xFFF8FAFD),
              borderRadius: BorderRadius.circular(AppBorders.padrao),
              border: Border.all(
                color: AppCores.outline,
                width: 1.6,
              ),
            ),
            child: Center(
              child: Icon(
                UIcons.boldRounded.settings_sliders,
                color: AppCores.fontes,
                size: AppTamanhos.iconeSearchbarFilter,
              ),
            ),
          ),
        ),
      ],
    );
  }
}
