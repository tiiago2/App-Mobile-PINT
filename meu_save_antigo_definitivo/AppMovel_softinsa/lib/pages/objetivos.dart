import 'package:flutter/material.dart';
import 'package:uicons/uicons.dart';
import '../controllers/badges_controller.dart';
import '../controllers/objetivos_controller.dart';
import '../idiomas/app_localizations.dart';
import '../variaveis/variaveis.dart';
import '../widgets/top_bar_actions.dart';

class ObjetivosScreen extends StatefulWidget {
  const ObjetivosScreen({super.key});

  @override
  State<ObjetivosScreen> createState() => _ObjetivosScreenState();
}

class _ObjetivosScreenState extends State<ObjetivosScreen> {
  int _abaObjetivos = 0; // 0 = Ativos, 1 = Expirados

  Map<String, dynamic>? _selectedBadgeForNewObjective;
  DateTime? _selectedDeadlineForNewObjective;

  final ObjetivosController _objetivosController = ObjetivosController.instance;
  final BadgesController _badgesController = BadgesController.instance;

  @override
  void initState() {
    super.initState();
    _objetivosController.carregar();
    _badgesController.carregar();
  }

  String _formatDateDisplay(DateTime dt) {
    return '${dt.day.toString().padLeft(2, '0')}/${dt.month.toString().padLeft(2, '0')}/${dt.year}';
  }

  Widget _buildBarraDeSelecaoObjetivos() {
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
          _buildSegment(0, AppLocalizations.of(context)?.abaAtivos ?? 'Ativos'),
          _buildSegment(1, AppLocalizations.of(context)?.abaExpirados ?? 'Expirados'),
        ],
      ),
    );
  }

  Widget _buildSegment(int index, String title) {
    final isSelected = _abaObjetivos == index;

    return Expanded(
      child: GestureDetector(
        onTap: () {
          setState(() {
            _abaObjetivos = index;
          });
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

  Widget _buildObjectiveCard(Map<String, dynamic> obj) {
    final String titulo = obj['titulo']?.toString() ??
        (obj['badge'] is Map ? obj['badge']['titulo']?.toString() : null) ??
        'Objetivo';
    final String categoria = obj['categoria']?.toString() ??
        (obj['badge'] is Map ? obj['badge']['categoria']?.toString() : null) ??
        'Geral';
    final String deadline = obj['deadline']?.toString() ?? obj['data_final']?.toString() ?? '';
    final int diasRestantes = (obj['diasRestantes'] as int?) ?? 0;
    final double progresso = (obj['progresso'] as num?)?.toDouble() ?? 0.0;
    final bool ativo = obj['ativo'] as bool? ?? true;
    final bool concluido = obj['concluido'] as bool? ?? false;
    final Color avatarColor = const Color(0xFF82ADE7);

    return Container(
      padding: const EdgeInsets.all(12.0),
      decoration: BoxDecoration(
        color: AppCores.branco,
        borderRadius: BorderRadius.circular(AppBorders.padrao),
        border: Border.all(color: AppCores.outline, width: 1.6),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: avatarColor.withValues(alpha: 0.15),
                  shape: BoxShape.circle,
                ),
                alignment: Alignment.center,
                child: Text(
                  titulo.length >= 2 ? titulo.substring(0, 2).toUpperCase() : 'OBJ',
                  style: TextStyle(
                    color: avatarColor,
                    fontSize: 14.0,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const SizedBox(width: 12.0),
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
                    ),
                    const SizedBox(height: 2.0),
                    Text(
                      categoria,
                      style: const TextStyle(
                        color: Color(0xFF8FA3B8),
                        fontSize: 11.0,
                      ),
                    ),
                  ],
                ),
              ),
              if (ativo)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10.0, vertical: 4.0),
                  decoration: BoxDecoration(
                    color: const Color(0xFFEEF4FF),
                    borderRadius: BorderRadius.circular(12.0),
                  ),
                  child: Text(
                    '$diasRestantes d',
                    style: const TextStyle(
                      color: AppCores.azulFundo,
                      fontSize: 11.0,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 16.0),
          Row(
            children: [
              Expanded(
                child: Container(
                  height: 6.0,
                  alignment: Alignment.centerLeft,
                  decoration: BoxDecoration(
                    color: const Color(0xFFF0F2F6),
                    borderRadius: BorderRadius.circular(3.0),
                  ),
                  child: FractionallySizedBox(
                    alignment: Alignment.centerLeft,
                    widthFactor: progresso.clamp(0.0, 1.0),
                    child: Container(
                      decoration: BoxDecoration(
                        color: concluido
                            ? AppCores.sucessoLogin
                            : (ativo ? AppCores.azulFundo : const Color(0xFFC40003)),
                        borderRadius: BorderRadius.circular(3.0),
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12.0),
              Text(
                '${(progresso * 100).toInt()}%',
                style: const TextStyle(
                  color: AppCores.fontes,
                  fontSize: 12.0,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12.0),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                AppLocalizations.of(context)?.dataLimite ?? 'Data Limite',
                style: const TextStyle(
                  color: Color(0xFF8FA3B8),
                  fontSize: 12.0,
                ),
              ),
              Text(
                deadline,
                style: const TextStyle(
                  color: AppCores.fontes,
                  fontSize: 12.0,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    return Scaffold(
      backgroundColor: AppCores.branco,
      appBar: AppBar(
        backgroundColor: AppCores.branco,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        centerTitle: false,
        titleSpacing: AppTamanhos.colocacao_titulo,
        title: Text(
          l10n?.objetivosTitulo ?? 'Objetivos de Badges',
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
        listenable: _objetivosController,
        builder: (context, _) {
          final objetivosExibidos = _abaObjetivos == 0
              ? _objetivosController.objetivosAtivos
              : _objetivosController.objetivosExpirados;

          return SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.all(AppTamanhos.margemEcra),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Formulário de Adicionar Objetivo
                  Container(
                    margin: const EdgeInsets.only(bottom: 24.0),
                    padding: const EdgeInsets.all(16.0),
                    decoration: BoxDecoration(
                      color: AppCores.fundo2,
                      borderRadius: BorderRadius.circular(AppBorders.padrao),
                      border: Border.all(color: AppCores.outline, width: 1.6),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          l10n?.novoObjetivo ?? 'Novo Objetivo',
                          style: const TextStyle(
                            fontSize: 16.0,
                            fontWeight: FontWeight.bold,
                            color: AppCores.fontes,
                          ),
                        ),
                        const SizedBox(height: 16.0),
                        // Dropdown de escolha do Badge
                        ListenableBuilder(
                          listenable: _badgesController,
                          builder: (context, _) {
                            final disponiveis = _badgesController.badges;
                            return DropdownButtonFormField<Map<String, dynamic>>(
                              value: _selectedBadgeForNewObjective,
                              dropdownColor: AppCores.branco,
                              icon: Icon(UIcons.boldRounded.angle_small_down, size: 18, color: AppCores.fontes),
                              decoration: InputDecoration(
                                labelText: l10n?.pesquisarBadge ?? 'Selecionar Badge',
                                labelStyle: const TextStyle(color: AppCores.fontes, fontSize: 13.0, fontWeight: FontWeight.bold),
                                filled: true,
                                fillColor: AppCores.branco,
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
                              items: disponiveis.map((b) {
                                return DropdownMenuItem<Map<String, dynamic>>(
                                  value: b,
                                  child: Text(b['nome_badge'] ?? b['titulo'] ?? ''),
                                );
                              }).toList(),
                              onChanged: (val) {
                                setState(() {
                                  _selectedBadgeForNewObjective = val;
                                });
                              },
                            );
                          },
                        ),
                        const SizedBox(height: 16.0),
                        // Seletor da Data Limite
                        InkWell(
                          onTap: () async {
                            final picked = await showDatePicker(
                              context: context,
                              initialDate: DateTime.now().add(const Duration(days: 1)),
                              firstDate: DateTime.now(),
                              lastDate: DateTime.now().add(const Duration(days: 365 * 5)),
                              builder: (context, child) {
                                return Theme(
                                  data: Theme.of(context).copyWith(
                                    colorScheme: const ColorScheme.light(
                                      primary: AppCores.azulFundo,
                                      onPrimary: Colors.white,
                                      onSurface: AppCores.fontes,
                                    ),
                                  ),
                                  child: child!,
                                );
                              },
                            );
                            if (picked != null) {
                              setState(() {
                                _selectedDeadlineForNewObjective = picked;
                              });
                            }
                          },
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 14.0),
                            decoration: BoxDecoration(
                              color: AppCores.branco,
                              borderRadius: BorderRadius.circular(AppBorders.padrao),
                              border: Border.all(color: AppCores.outline),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  _selectedDeadlineForNewObjective == null
                                      ? 'Data Limite (Deadline)'
                                      : _formatDateDisplay(_selectedDeadlineForNewObjective!),
                                  style: TextStyle(
                                    color: _selectedDeadlineForNewObjective == null
                                        ? AppCores.fontes.withValues(alpha: 0.6)
                                        : AppCores.fontes,
                                    fontSize: 14.0,
                                  ),
                                ),
                                Icon(
                                  UIcons.boldRounded.calendar,
                                  color: AppCores.fontes,
                                  size: 18.0,
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 16.0),
                        // Botão Adicionar
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            onPressed: () async {
                              if (_selectedBadgeForNewObjective == null ||
                                  _selectedDeadlineForNewObjective == null) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text('Por favor, selecione o badge e a data limite.'),
                                  ),
                                );
                                return;
                              }

                              final badgeId = _selectedBadgeForNewObjective!['id_badge'] as int? ??
                                  _selectedBadgeForNewObjective!['id'] as int?;
                              if (badgeId == null) return;

                              final dateStr = _selectedDeadlineForNewObjective!.toIso8601String();

                              try {
                                await _objetivosController.criarObjetivo(
                                  badgeId: badgeId,
                                  dataFinal: dateStr,
                                  titulo: _selectedBadgeForNewObjective!['nome_badge'] ?? '',
                                );

                                setState(() {
                                  _selectedBadgeForNewObjective = null;
                                  _selectedDeadlineForNewObjective = null;
                                });

                                if (mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text('Objetivo adicionado com sucesso!'),
                                    ),
                                  );
                                }
                              } catch (e) {
                                if (mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(content: Text('Erro ao criar objetivo: $e')),
                                  );
                                }
                              }
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppCores.azulFundo,
                              padding: const EdgeInsets.symmetric(vertical: 14.0),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(AppBorders.padrao),
                              ),
                            ),
                            child: Text(
                              l10n?.authConfirmar ?? 'Confirmar',
                              style: const TextStyle(
                                color: AppCores.branco,
                                fontWeight: FontWeight.bold,
                                fontSize: 14.0,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  // Seletor de Abas
                  _buildBarraDeSelecaoObjetivos(),
                  const SizedBox(height: 16.0),
                  // Listagem de Objetivos
                  if (objetivosExibidos.isEmpty)
                    Container(
                      padding: const EdgeInsets.all(24.0),
                      decoration: BoxDecoration(
                        color: AppCores.fundo2,
                        borderRadius: BorderRadius.circular(AppBorders.padrao),
                        border: Border.all(color: AppCores.outline),
                      ),
                      child: Center(
                        child: Text(
                          _abaObjetivos == 0
                              ? (l10n?.nenhumObjetivoAtivo ?? 'Nenhum objetivo ativo.')
                              : (l10n?.nenhumObjetivoExpirado ?? 'Nenhum objetivo expirado.'),
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
                      itemCount: objetivosExibidos.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 12.0),
                      itemBuilder: (context, index) {
                        return _buildObjectiveCard(objetivosExibidos[index]);
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
