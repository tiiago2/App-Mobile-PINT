import 'package:flutter/material.dart';
import 'package:uicons/uicons.dart';
import '../variaveis/variaveis.dart';
import '../idiomas/app_localizations.dart';
import '../widgets/top_bar_actions.dart';
import '../controllers/objetivos_controller.dart';
import 'badge_detalhe.dart';

class ObjetivosScreen extends StatefulWidget {
  const ObjetivosScreen({super.key});

  @override
  State<ObjetivosScreen> createState() => _ObjetivosScreenState();
}

class _ObjetivosScreenState extends State<ObjetivosScreen> {
  int _abaObjetivos = 0; // 0 = Ativos, 1 = Expirados

  // Variáveis para adicionar objetivos
  int? _selectedBadgeIdForNewObjective;
  DateTime? _selectedDeadlineForNewObjective;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ObjetivosController.instance.carregarDadosObjetivos();
    });
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
    final int localId = obj['id'] as int;
    final String titulo = obj['titulo'] as String;
    final String categoria = obj['categoria'] as String;
    final String deadline = obj['deadline'] as String;
    final int diasRestantes = obj['diasRestantes'] as int;
    final double progresso = obj['progresso'] as double;
    final bool ativo = obj['ativo'] as bool? ?? true;
    final bool concluido = obj['concluido'] as bool? ?? false;
    final Color avatarColor = obj['avatarColor'] as Color? ?? const Color(0xFF82ADE7);
    final String? aviso = obj['aviso'] as String?;
    final String? avisoSucesso = obj['avisoSucesso'] as String?;
    final String? imagem = obj['imagem'] as String?;

    return Dismissible(
      key: Key('obj_$localId'),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20.0),
        decoration: BoxDecoration(
          color: const Color(0xFFC40003),
          borderRadius: BorderRadius.circular(AppBorders.padrao),
        ),
        child: const Icon(Icons.delete, color: Colors.white),
      ),
      onDismissed: (direction) {
        ObjetivosController.instance.eliminarObjetivo(localId).catchError((err) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Erro ao eliminar: $err')),
          );
        });
      },
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => BadgeDetalheScreen(badge: obj),
            ),
          );
        },
        child: Container(
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
                // Avatar Circular com Imagem ou Iniciais do Badge
                Container(
                  width: 38,
                  height: 38,
                  decoration: BoxDecoration(
                    color: avatarColor.withValues(alpha: 0.15),
                    shape: BoxShape.circle,
                    image: imagem != null && imagem.isNotEmpty
                        ? DecorationImage(
                            image: NetworkImage(imagem),
                            fit: BoxFit.cover,
                          )
                        : null,
                  ),
                  alignment: Alignment.center,
                  child: imagem != null && imagem.isNotEmpty
                      ? null
                      : Text(
                          titulo.isNotEmpty ? titulo.substring(0, 1).toUpperCase() : 'B',
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
                 // Dias Restantes (Pill) ou Tag de Concluído/Expirado
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
                  )
                else
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10.0, vertical: 4.0),
                    decoration: BoxDecoration(
                      color: concluido
                          ? const Color(0xFFE6F4EA) // Verde claro
                          : const Color(0xFFFCE8E6), // Vermelho claro
                      borderRadius: BorderRadius.circular(8.0),
                      border: Border.all(
                        color: concluido
                            ? const Color(0xFF137333) // Verde escuro
                            : const Color(0xFFC5221F), // Vermelho escuro
                        width: 1.2,
                      ),
                    ),
                    child: Text(
                      concluido 
                          ? (AppLocalizations.of(context)?.completo ?? 'Concluído')
                          : (AppLocalizations.of(context)?.expirado ?? 'Não Concluído'),
                      style: TextStyle(
                        color: concluido
                            ? const Color(0xFF137333)
                            : const Color(0xFFC5221F),
                        fontSize: 11.0,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
              ],
            ),
            if (ativo) ...[
              const SizedBox(height: 12.0),
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
                            color: AppCores.azulFundo,
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
            ],
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
    ),
  ),
);
}

  // ── Build ─────────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final controller = ObjetivosController.instance;

    return AnimatedBuilder(
      animation: controller,
      builder: (context, _) {
        final todosObjetivos = _abaObjetivos == 0 ? controller.ativos : controller.expirados;

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
          body: controller.isLoading
              ? const Center(child: CircularProgressIndicator())
              : SingleChildScrollView(
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
                              DropdownButtonFormField<int>(
                                isExpanded: true,
                                value: _selectedBadgeIdForNewObjective,
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
                                items: controller.disponiveisBadges.map((badge) {
                                  return DropdownMenuItem<int>(
                                    value: badge['id_badge'] as int,
                                    child: Text(badge['nome_badge'] ?? ''),
                                  );
                                }).toList(),
                                onChanged: (val) {
                                  setState(() {
                                    _selectedBadgeIdForNewObjective = val;
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
                                    if (_selectedBadgeIdForNewObjective == null ||
                                        _selectedDeadlineForNewObjective == null) {
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        const SnackBar(
                                          content: Text('Por favor, selecione o badge e a data limite.'),
                                        ),
                                      );
                                      return;
                                    }

                                    final badgeId = _selectedBadgeIdForNewObjective!;
                                    final deadline = _selectedDeadlineForNewObjective!;

                                    controller.criarNovoObjetivo(
                                      badgeId: badgeId,
                                      dataLimite: deadline,
                                    ).then((_) {
                                      setState(() {
                                        _selectedBadgeIdForNewObjective = null;
                                        _selectedDeadlineForNewObjective = null;
                                      });
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        const SnackBar(
                                          content: Text('Objetivo adicionado com sucesso!'),
                                        ),
                                      );
                                    }).catchError((err) {
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        SnackBar(
                                          content: Text('Erro ao adicionar objetivo: $err'),
                                        ),
                                      );
                                    });
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
      },
    );
  }
}
