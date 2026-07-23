import 'package:flutter/material.dart';
import 'package:uicons/uicons.dart';
import '../variaveis/variaveis.dart';
import '../idiomas/app_localizations.dart';
import '../widgets/top_bar_actions.dart';

class ObjetivosScreen extends StatefulWidget {
  const ObjetivosScreen({super.key});

  @override
  State<ObjetivosScreen> createState() => _ObjetivosScreenState();
}

class _ObjetivosScreenState extends State<ObjetivosScreen> {
  int _abaObjetivos = 0; // 0 = Ativos, 1 = Expirados

  // Variáveis para adicionar objetivos
  Map<String, String>? _selectedBadgeForNewObjective;
  DateTime? _selectedDeadlineForNewObjective;

  final List<Map<String, String>> _disponiveisBadges = const [
    {'titulo': 'Low Code Básico', 'categoria': 'Low Code'},
    {'titulo': 'Cloud Architect', 'categoria': 'Cloud Computing'},
    {'titulo': 'Git & Version Control', 'categoria': 'Development Tools'},
    {'titulo': 'Mobile Dev Pro', 'categoria': 'Mobile Dev'},
    {'titulo': 'Cyber Security Essentials', 'categoria': 'Segurança'},
    {'titulo': 'OutSystems Associate', 'categoria': 'Low Code'},
    {'titulo': 'Flutter Fundamentals', 'categoria': 'Mobile Dev'},
    {'titulo': 'Scrum Master Avançado', 'categoria': 'Agile Management'},
    {'titulo': 'Design Básico', 'categoria': 'Design'},
    {'titulo': 'DevOps Básico', 'categoria': 'DevOps'},
    {'titulo': 'Data Básico', 'categoria': 'Data'},
    {'titulo': 'AI Básico', 'categoria': 'AI'},
  ];

  late final Map<String, List<Map<String, dynamic>>> _mockObjetivos;

  @override
  void initState() {
    super.initState();
    final today = DateTime.now();

    final d2 = today.add(const Duration(days: 2));
    final d8 = today.add(const Duration(days: 8));
    final d13 = today.add(const Duration(days: 13));
    final d20 = today.add(const Duration(days: 20));
    final dMinus15 = today.subtract(const Duration(days: 15));
    final dMinus5 = today.subtract(const Duration(days: 5));
    final dMinus20 = today.subtract(const Duration(days: 20));

    _mockObjetivos = {
      'key2': [
        {
          'titulo': 'Low Code Básico',
          'categoria': 'Low Code',
          'deadline': _formatDateDisplay(d2),
          'diasRestantes': 2,
          'progresso': 0.6,
          'ativo': true,
          'avatarColor': const Color(0xFF82ADE7),
        }
      ],
      'key8': [
        {
          'titulo': 'Cloud Architect',
          'categoria': 'Cloud Computing',
          'deadline': _formatDateDisplay(d8),
          'diasRestantes': 8,
          'progresso': 0.3,
          'ativo': true,
          'avatarColor': const Color(0xFFEC4899),
        }
      ],
      'key13': [
        {
          'titulo': 'Git & Version Control',
          'categoria': 'Development Tools',
          'deadline': _formatDateDisplay(d13),
          'diasRestantes': 13,
          'progresso': 0.85,
          'ativo': true,
          'avatarColor': const Color(0xFF10B981),
        }
      ],
      'key20': [
        {
          'titulo': 'Mobile Dev Pro',
          'categoria': 'Mobile Dev',
          'deadline': _formatDateDisplay(d20),
          'diasRestantes': 20,
          'progresso': 0.15,
          'ativo': true,
          'avatarColor': const Color(0xFF06B6D4),
        }
      ],
      'keyMinus15': [
        {
          'titulo': 'OutSystems Associate',
          'categoria': 'Low Code',
          'deadline': _formatDateDisplay(dMinus15),
          'diasRestantes': 0,
          'progresso': 0.2,
          'ativo': false,
          'concluido': false,
          'avatarColor': const Color(0xFFE9D78E),
          'aviso': 'Este Objetivo expirou em ${_formatDateDisplay(dMinus15)}. Para manteres as tuas metas em dia, renova o objetivo.',
        }
      ],
      'keyMinus5': [
        {
          'titulo': 'Flutter Fundamentals',
          'categoria': 'Mobile Dev',
          'deadline': _formatDateDisplay(dMinus5),
          'diasRestantes': 0,
          'progresso': 1.0,
          'ativo': false,
          'concluido': true,
          'avatarColor': const Color(0xFF10B981),
          'avisoSucesso': 'Objetivo concluído com sucesso a ${_formatDateDisplay(dMinus5)}! Badge obtido com sucesso.',
        }
      ],
      'keyMinus20': [
        {
          'titulo': 'Scrum Master Avançado',
          'categoria': 'Agile Management',
          'deadline': _formatDateDisplay(dMinus20),
          'diasRestantes': 0,
          'progresso': 0.4,
          'ativo': false,
          'concluido': false,
          'avatarColor': const Color(0xFF8B5CF6),
          'aviso': 'Este Objetivo expirou em ${_formatDateDisplay(dMinus20)}. Para manteres as tuas metas em dia, renova o objetivo.',
        }
      ],
    };
  }

  String _formatDateDisplay(DateTime dt) {
    return '${dt.day.toString().padLeft(2, '0')}/${dt.month.toString().padLeft(2, '0')}/${dt.year}';
  }

  // ── Seletor Visual de Abas (Estilo Galeria) ────────────────────────────────
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

  // ── Card de Objetivo Proposto ─────────────────────────────────────────────
  Widget _buildObjectiveCard(Map<String, dynamic> obj) {
    final String titulo = obj['titulo'] as String;
    final String categoria = obj['categoria'] as String;
    final String deadline = obj['deadline'] as String;
    final int diasRestantes = obj['diasRestantes'] as int;
    final double progresso = obj['progresso'] as double;
    final bool ativo = obj['ativo'] as bool? ?? true;
    final bool concluido = obj['concluido'] as bool? ?? false;
    final Color avatarColor = obj['avatarColor'] as Color;
    final String? aviso = obj['aviso'] as String?;
    final String? avisoSucesso = obj['avisoSucesso'] as String?;

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
              // Avatar Circular com Iniciais do Badge
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: avatarColor.withValues(alpha: 0.15),
                  shape: BoxShape.circle,
                ),
                alignment: Alignment.center,
                child: Text(
                  titulo.substring(0, 2).toUpperCase(),
                  style: TextStyle(
                    color: avatarColor,
                    fontSize: 14.0,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const SizedBox(width: 12.0),
              // Titulo e Categoria
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
              // Dias Restantes (Pill)
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
          // Linha de Progresso e Percentagem
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
                    widthFactor: progresso,
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
          // Data Limite (Footer)
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
          // Avisos adicionais de conclusão ou expiração
          if (avisoSucesso != null) ...[
            const SizedBox(height: 12.0),
            Container(
              padding: const EdgeInsets.all(10.0),
              decoration: BoxDecoration(
                color: const Color(0xFFECFDF5),
                border: Border.all(
                  color: const Color(0xFF10B981).withValues(alpha: 0.3),
                ),
                borderRadius: BorderRadius.circular(10.0),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(
                    Icons.check_circle_outline_rounded,
                    color: Color(0xFF065F46),
                    size: 14.0,
                  ),
                  const SizedBox(width: 6.0),
                  Expanded(
                    child: Text(
                      avisoSucesso,
                      style: const TextStyle(
                        color: Color(0xFF065F46),
                        fontSize: 10.0,
                        height: 1.4,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ] else if (!ativo && aviso != null) ...[
            const SizedBox(height: 12.0),
            Container(
              padding: const EdgeInsets.all(10.0),
              decoration: BoxDecoration(
                color: const Color(0xFFFEE2E2),
                border: Border.all(
                  color: const Color(0xFFD42A2A).withValues(alpha: 0.3),
                ),
                borderRadius: BorderRadius.circular(10.0),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(
                    Icons.history_toggle_off_rounded,
                    color: Color(0xFF991B1B),
                    size: 14.0,
                  ),
                  const SizedBox(width: 6.0),
                  Expanded(
                    child: Text(
                      aviso,
                      style: const TextStyle(
                        color: Color(0xFF991B1B),
                        fontSize: 10.0,
                        height: 1.4,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  // ── Build ─────────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final todosObjetivos = _mockObjetivos.values
        .expand((x) => x)
        .where((obj) => (obj['ativo'] ?? true) == (_abaObjetivos == 0))
        .toList();

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
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(AppTamanhos.margemEcra),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Widget de Adicionar Objetivo
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
                    DropdownButtonFormField<Map<String, String>>(
                      initialValue: _selectedBadgeForNewObjective,
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
                      items: _disponiveisBadges.map((badge) {
                        return DropdownMenuItem<Map<String, String>>(
                          value: badge,
                          child: Text(badge['titulo'] ?? ''),
                        );
                      }).toList(),
                      onChanged: (val) {
                        setState(() {
                          _selectedBadgeForNewObjective = val;
                        });
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
                                textButtonTheme: TextButtonThemeData(
                                  style: TextButton.styleFrom(
                                    foregroundColor: AppCores.azulFundo,
                                  ),
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
                                  : '${_selectedDeadlineForNewObjective!.day.toString().padLeft(2, '0')}/${_selectedDeadlineForNewObjective!.month.toString().padLeft(2, '0')}/${_selectedDeadlineForNewObjective!.year}',
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
                        onPressed: () {
                          if (_selectedBadgeForNewObjective == null ||
                              _selectedDeadlineForNewObjective == null) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Por favor, selecione o badge e a data limite.'),
                              ),
                            );
                            return;
                          }

                          final pickedDate = _selectedDeadlineForNewObjective!;
                          final dateStr = 'custom_${pickedDate.year}_${pickedDate.month}_${pickedDate.day}';
                          final displayDeadline = '${pickedDate.day.toString().padLeft(2, '0')}/${pickedDate.month.toString().padLeft(2, '0')}/${pickedDate.year}';
                          final daysLeft = pickedDate.difference(DateTime.now()).inDays + 1;

                          final newObjective = {
                            'titulo': _selectedBadgeForNewObjective!['titulo']!,
                            'categoria': _selectedBadgeForNewObjective!['categoria']!,
                            'deadline': displayDeadline,
                            'diasRestantes': daysLeft < 0 ? 0 : daysLeft,
                            'progresso': 0.0,
                            'ativo': true,
                            'avatarColor': const Color(0xFF82ADE7),
                          };

                          setState(() {
                            if (!_mockObjetivos.containsKey(dateStr)) {
                              _mockObjetivos[dateStr] = [];
                            }
                            _mockObjetivos[dateStr]!.add(newObjective);
                            
                            // Limpar formulário
                            _selectedBadgeForNewObjective = null;
                            _selectedDeadlineForNewObjective = null;
                          });

                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Objetivo adicionado com sucesso!'),
                            ),
                          );
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
              // 1. Seletor de Abas (Ativos / Expirados - Estilo Galeria)
              _buildBarraDeSelecaoObjetivos(),
              const SizedBox(height: 16.0),
              // 2. Listagem de Objetivos Filtrados
              if (todosObjetivos.isEmpty)
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
                        color: AppCores.fontes.withOpacity(0.6),
                        fontSize: 14.0,
                      ),
                    ),
                  ),
                )
              else
                ListView.separated(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: todosObjetivos.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 12.0),
                  itemBuilder: (context, index) {
                    return _buildObjectiveCard(todosObjetivos[index]);
                  },
                ),
            ],
          ),
        ),
      ),
    );
  }
}
