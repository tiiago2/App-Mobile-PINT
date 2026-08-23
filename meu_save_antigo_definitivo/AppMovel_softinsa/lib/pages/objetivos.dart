import 'package:flutter/material.dart';
import 'package:uicons/uicons.dart';
import '../variaveis/variaveis.dart';
import '../idiomas/app_localizations.dart';
import '../widgets/top_bar_actions.dart';
import '../controllers/objetivos_controller.dart';
import 'badge_detalhe.dart';

const List<String> _mesesPT = [
  'Janeiro',
  'Fevereiro',
  'Março',
  'Abril',
  'Maio',
  'Junho',
  'Julho',
  'Agosto',
  'Setembro',
  'Outubro',
  'Novembro',
  'Dezembro',
];

const List<String> _diasSemana = [
  'Dom',
  'Seg',
  'Ter',
  'Qua',
  'Qui',
  'Sex',
  'Sáb',
];

class ObjetivosScreen extends StatefulWidget {
  const ObjetivosScreen({super.key});

  @override
  State<ObjetivosScreen> createState() => _ObjetivosScreenState();
}

class _ObjetivosScreenState extends State<ObjetivosScreen> {
  // ── ESTADO DO FORMULÁRIO ────────────────────────────────────────────────
  Map<String, dynamic>? _badgeSelecionado;
  DateTime? _dataSelecionada;
  bool _isSubmitting = false;

  // ── ESTADO DA LISTA / CALENDÁRIO ────────────────────────────────────────
  DateTime? _diaSelecionado;
  String _viewMode = 'progresso'; // 'progresso' | 'historico'
  String _historicoFiltro = 'todos'; // 'todos' | 'concluidos' | 'expirados'

  // ── CONTROLLER ──────────────────────────────────────────────────────────
  final ObjetivosController _ctrl = ObjetivosController.instance;

  DateTime get _hoje {
    final now = DateTime.now();
    return DateTime(now.year, now.month, now.day);
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _ctrl.carregarDadosObjetivos();
    });
  }

  Color _corObjetivo(Map<String, dynamic> obj) {
    final concluido = obj['concluido'] == true;
    final ativo = obj['ativo'] == true;
    if (concluido) return AppCores.sucessoLogin;
    if (!ativo) return AppCores.erroLogin;
    return const Color(0xFFE17100);
  }

  String _estadoTexto(Map<String, dynamic> obj) {
    final concluido = obj['concluido'] == true;
    final ativo = obj['ativo'] == true;
    if (concluido) return 'Concluído';
    if (!ativo) return 'Expirado';
    final pct = ((obj['progresso'] as double? ?? 0.0) * 100).toInt();
    return '$pct%';
  }

  DateTime? _parseDataObjetivo(Map<String, dynamic> obj) {
    final deadline = obj['deadline']?.toString() ?? '';
    if (deadline.isEmpty) return null;
    final partes = deadline.split('/');
    if (partes.length == 3) {
      final dia = int.tryParse(partes[0]);
      final mes = int.tryParse(partes[1]);
      final ano = int.tryParse(partes[2]);
      if (dia != null && mes != null && ano != null) {
        return DateTime(ano, mes, dia);
      }
    }
    return DateTime.tryParse(deadline);
  }

  bool _mesmoDia(DateTime d1, DateTime d2) {
    return d1.year == d2.year && d1.month == d2.month && d1.day == d2.day;
  }

  List<Map<String, dynamic>> get _todosObjetivos {
    return [..._ctrl.ativos, ..._ctrl.expirados];
  }

  List<Map<String, dynamic>> get _objetivosFiltrados {
    return _todosObjetivos.where((obj) {
      final dataLimite = _parseDataObjetivo(obj);
      final concluido = obj['concluido'] == true;
      final ativo = obj['ativo'] == true;
      final isHistorico = !ativo || concluido;

      if (_viewMode == 'historico') {
        if (isHistorico == false) return false;
        if (_historicoFiltro == 'concluidos' && !concluido) return false;
        if (_historicoFiltro == 'expirados' && concluido) return false;
        if (dataLimite != null &&
            _diaSelecionado != null &&
            !_mesmoDia(dataLimite, _diaSelecionado!)) {
          return false;
        }
        return true;
      } else {
        if (isHistorico) return false;
        if (dataLimite != null &&
            _diaSelecionado != null &&
            !_mesmoDia(dataLimite, _diaSelecionado!)) {
          return false;
        }
        return true;
      }
    }).toList();
  }

  Future<void> _criarObjetivo() async {
    if (_badgeSelecionado == null ||
        _dataSelecionada == null ||
        _isSubmitting) {
      return;
    }

    final badgeId = _badgeSelecionado!['id_badge'] as int?;
    if (badgeId == null) return;

    setState(() => _isSubmitting = true);

    try {
      await _ctrl.criarNovoObjetivo(
        badgeId: badgeId,
        dataLimite: _dataSelecionada!,
      );

      if (mounted) {
        setState(() {
          _badgeSelecionado = null;
          _dataSelecionada = null;
          _isSubmitting = false;
          _diaSelecionado = null;
        });
        _mostrarSnackBar('Objetivo proposto com sucesso!');
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isSubmitting = false);
        _mostrarSnackBar('Erro ao propor objetivo: $e', isErro: true);
      }
    }
  }

  Future<void> _removerObjetivo(int localId) async {
    try {
      await _ctrl.eliminarObjetivo(localId);
      if (mounted) {
        setState(() => _diaSelecionado = null);
        _mostrarSnackBar('Objetivo removido.');
      }
    } catch (e) {
      if (mounted) {
        _mostrarSnackBar('Erro ao remover objetivo: $e', isErro: true);
      }
    }
  }

  void _confirmarRemocao(Map<String, dynamic> obj) {
    final localId = obj['id'] as int? ?? 0;
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppCores.branco,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppBorders.padrao),
        ),
        title: const Text(
          'Remover Objetivo',
          style: TextStyle(
            color: AppCores.fontes,
            fontSize: 18.0,
            fontWeight: FontWeight.bold,
          ),
        ),
        content: const Text(
          'Tens a certeza que desejas remover este objetivo? Esta ação não poderá ser revertida.',
          style: TextStyle(color: AppCores.fontes, fontSize: 14.0),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text(
              'Cancelar',
              style: TextStyle(color: AppCores.fontes),
            ),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              _removerObjetivo(localId);
            },
            child: const Text(
              'Remover',
              style: TextStyle(
                color: AppCores.erroLogin,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _handleDiaClick(DateTime? dia) {
    setState(() => _diaSelecionado = dia);
    if (dia == null) return;

    final objsNesteDia = _todosObjetivos.where((o) {
      final d = _parseDataObjetivo(o);
      return d != null && _mesmoDia(d, dia);
    }).toList();

    if (objsNesteDia.isEmpty && !dia.isBefore(_hoje)) {
      setState(() => _dataSelecionada = dia);
      return;
    }

    bool temProgresso = false;
    bool temHistorico = false;
    for (final o in objsNesteDia) {
      final concluido = o['concluido'] == true;
      final ativo = o['ativo'] == true;
      if (concluido || !ativo) {
        temHistorico = true;
      } else {
        temProgresso = true;
      }
    }

    setState(() {
      if (_viewMode == 'progresso' && !temProgresso && temHistorico) {
        _viewMode = 'historico';
        _historicoFiltro = 'todos';
      } else if (_viewMode == 'historico' && !temHistorico && temProgresso) {
        _viewMode = 'progresso';
      }
    });
  }

  void _mostrarSnackBar(String mensagem, {bool isErro = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(mensagem),
        backgroundColor: isErro ? AppCores.erroLogin : AppCores.azulFundo,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppBorders.padrao),
        ),
      ),
    );
  }

  void _abrirBadgePicker() {
    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (_) => _BadgePickerModal(
        badges: _ctrl.disponiveisBadges,
        onSelecionar: (badge) => setState(() => _badgeSelecionado = badge),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    return AnimatedBuilder(
      animation: _ctrl,
      builder: (context, _) {
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
                fontWeight: FontWeight.bold,
              ),
            ),
            actions: const [TopBarActions()],
          ),
          body: RefreshIndicator(
            onRefresh: () => _ctrl.carregarDadosObjetivos(),
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.symmetric(
                horizontal: AppTamanhos.margemEcra,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildFormulario(),
                  const SizedBox(height: 24),
                  _buildCalendario(),
                  const SizedBox(height: 24),
                  _buildTabs(),
                  const SizedBox(height: 16),
                  _buildLista(),
                  const SizedBox(height: 24),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  // ── FORMULÁRIO ──────────────────────────────────────────────────────────
  Widget _buildFormulario() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20.0),
      decoration: BoxDecoration(
        color: AppCores.branco,
        borderRadius: BorderRadius.circular(AppBorders.padrao),
        border: Border.all(color: AppCores.outline),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Propor Objetivos',
            style: TextStyle(
              color: AppCores.fontes,
              fontSize: 18.0,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 20),
          LayoutBuilder(
            builder: (context, constraints) {
              final campos = Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(child: _buildBadgePickerField()),
                  const SizedBox(width: 16),
                  Expanded(child: _buildDatePickerField()),
                ],
              );
              if (constraints.maxWidth < 360) {
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildBadgePickerField(),
                    const SizedBox(height: 16),
                    _buildDatePickerField(),
                  ],
                );
              }
              return campos;
            },
          ),
          const SizedBox(height: 16),
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Icon(
                UIcons.boldRounded.info,
                color: AppCores.azulFundo,
                size: 14,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  _badgeSelecionado == null && _dataSelecionada == null
                      ? 'Seleciona um badge e uma data para submeteres.'
                      : _badgeSelecionado == null
                      ? 'Seleciona um badge para continuar.'
                      : _dataSelecionada == null
                      ? 'Seleciona uma data limite para continuar.'
                      : 'Podes agora propor o teu objetivo.',
                  style: const TextStyle(
                    color: Color(0xFF8FA3B8),
                    fontSize: 12.0,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              SizedBox(
                height: 40,
                child: ElevatedButton(
                  onPressed:
                      (_badgeSelecionado != null &&
                          _dataSelecionada != null &&
                          !_isSubmitting)
                      ? _criarObjetivo
                      : null,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppCores.azulFundo,
                    foregroundColor: AppCores.branco,
                    elevation: 0,
                    disabledBackgroundColor: AppCores.azulFundo.withValues(alpha: 
                      0.4,
                    ),
                    disabledForegroundColor: AppCores.branco,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(
                        AppBorders.padrao_pequeno,
                      ),
                    ),
                    padding: const EdgeInsets.symmetric(horizontal: 20.0),
                  ),
                  child: _isSubmitting
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(
                            color: AppCores.branco,
                            strokeWidth: 2,
                          ),
                        )
                      : const Text(
                          'Submeter Objetivo',
                          style: TextStyle(
                            fontSize: 14.0,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildBadgePickerField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Badge a conquistar',
          style: TextStyle(
            color: AppCores.fontes,
            fontSize: 13.0,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 8),
        GestureDetector(
          onTap: _abrirBadgePicker,
          child: Container(
            height: 44,
            padding: const EdgeInsets.symmetric(horizontal: 14.0),
            decoration: BoxDecoration(
              color: AppCores.branco,
              borderRadius: BorderRadius.circular(AppBorders.padrao_pequeno),
              border: Border.all(
                color: _badgeSelecionado != null
                    ? AppCores.azulFundo
                    : AppCores.outline,
              ),
            ),
            child: Row(
              children: [
                if (_badgeSelecionado != null) ...[
                  _buildMiniBadgeCircle(_badgeSelecionado!),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      _badgeSelecionado!['nome_badge']?.toString() ?? 'Badge',
                      style: const TextStyle(
                        color: AppCores.fontes,
                        fontSize: 14.0,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  GestureDetector(
                    onTap: () => setState(() => _badgeSelecionado = null),
                    child: Icon(
                      UIcons.boldRounded.cross_circle,
                      color: const Color(0xFFAAB7C4),
                      size: 20,
                    ),
                  ),
                ] else ...[
                  Icon(
                    UIcons.boldRounded.star,
                    color: const Color(0xFFAAB7C4),
                    size: 16,
                  ),
                  const SizedBox(width: 10),
                  const Expanded(
                    child: Text(
                      'Escolhe um badge...',
                      style: TextStyle(
                        color: Color(0xFFAAB7C4),
                        fontSize: 14.0,
                      ),
                    ),
                  ),
                  Icon(
                    UIcons.boldRounded.expand,
                    color: const Color(0xFFAAB7C4),
                    size: 14,
                  ),
                ],
              ],
            ),
          ),
        ),
        const SizedBox(height: 6),
        const Text(
          'Seleciona o badge que pretendes conquistar.',
          style: TextStyle(color: Color(0xFF8FA3B8), fontSize: 11.0),
        ),
      ],
    );
  }

  Widget _buildDatePickerField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Data Limite Proposta',
          style: TextStyle(
            color: AppCores.fontes,
            fontSize: 13.0,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 8),
        GestureDetector(
          onTap: () async {
            final data = await showDatePicker(
              context: context,
              initialDate: _dataSelecionada ?? _hoje,
              firstDate: _hoje,
              lastDate: DateTime(_hoje.year + 2),
              builder: (context, child) {
                return Theme(
                  data: Theme.of(context).copyWith(
                    colorScheme: const ColorScheme.light(
                      primary: AppCores.azulFundo,
                      onPrimary: AppCores.branco,
                      onSurface: AppCores.fontes,
                    ),
                  ),
                  child: child!,
                );
              },
            );
            if (data != null) setState(() => _dataSelecionada = data);
          },
          child: Container(
            height: 44,
            padding: const EdgeInsets.symmetric(horizontal: 14.0),
            decoration: BoxDecoration(
              color: AppCores.branco,
              borderRadius: BorderRadius.circular(AppBorders.padrao_pequeno),
              border: Border.all(
                color: _dataSelecionada != null
                    ? AppCores.azulFundo
                    : AppCores.outline,
              ),
            ),
            child: Row(
              children: [
                Icon(
                  UIcons.boldRounded.calendar,
                  color: const Color(0xFFAAB7C4),
                  size: 16,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    _dataSelecionada != null
                        ? '${_dataSelecionada!.day} de ${_mesesPT[_dataSelecionada!.month - 1]} de ${_dataSelecionada!.year}'
                        : 'Indique a data...',
                    style: TextStyle(
                      color: _dataSelecionada != null
                          ? AppCores.fontes
                          : const Color(0xFFAAB7C4),
                      fontSize: 14.0,
                    ),
                  ),
                ),
                if (_dataSelecionada != null)
                  GestureDetector(
                    onTap: () => setState(() => _dataSelecionada = null),
                    child: Icon(
                      UIcons.boldRounded.cross_circle,
                      color: const Color(0xFFAAB7C4),
                      size: 20,
                    ),
                  ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 6),
        const Text(
          'Define a data até quando pretendes completar este objetivo.',
          style: TextStyle(color: Color(0xFF8FA3B8), fontSize: 11.0),
        ),
      ],
    );
  }

  // ── CALENDÁRIO ──────────────────────────────────────────────────────────
  Widget _buildCalendario() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20.0),
      decoration: BoxDecoration(
        color: AppCores.branco,
        borderRadius: BorderRadius.circular(AppBorders.padrao),
        border: Border.all(color: AppCores.outline),
      ),
      child: Column(
        children: [
          _CalendarioMensal(
            objetivos: _todosObjetivos,
            diaSelecionado: _diaSelecionado,
            hoje: _hoje,
            onDiaClick: _handleDiaClick,
            corObjetivo: _corObjetivo,
            parseData: _parseDataObjetivo,
          ),
          const SizedBox(height: 16),
          _buildLegendaCalendario(),
        ],
      ),
    );
  }

  Widget _buildLegendaCalendario() {
    final l10n = AppLocalizations.of(context);
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceAround,
      children: [
        _buildLegendaItem(
          l10n?.concluidos ?? 'Concluídos',
          AppCores.sucessoLogin,
        ),
        _buildLegendaItem(
          l10n?.emProgresso ?? 'Em progresso',
          const Color(0xFFE17100),
        ),
        _buildLegendaItem(l10n?.expirados ?? 'Expirados', AppCores.erroLogin),
      ],
    );
  }

  Widget _buildLegendaItem(String label, Color color) {
    return Row(
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 6),
        Text(
          label,
          style: const TextStyle(
            color: Color(0xFF8FA3B8),
            fontSize: 11.0,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  // ── TABS ────────────────────────────────────────────────────────────────
  Widget _buildTabs() {
    final l10n = AppLocalizations.of(context);
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: _buildTabButton(
                l10n?.emProgresso ?? 'Em progresso',
                'progresso',
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildTabButton(
                l10n?.historicoTitulo ?? 'Histórico',
                'historico',
              ),
            ),
          ],
        ),
        if (_viewMode == 'historico') ...[
          const SizedBox(height: 12),
          Row(
            children: [
              _buildSubFiltroButton(l10n?.todos ?? 'Todos', 'todos'),
              const SizedBox(width: 8),
              _buildSubFiltroButton(
                l10n?.concluidos ?? 'Concluídos',
                'concluidos',
              ),
              const SizedBox(width: 8),
              _buildSubFiltroButton(
                l10n?.expirados ?? 'Expirados',
                'expirados',
              ),
            ],
          ),
        ],
      ],
    );
  }

  Widget _buildTabButton(String label, String value) {
    final isActive = _viewMode == value;
    return GestureDetector(
      onTap: () => setState(() {
        _viewMode = value;
        _diaSelecionado = null;
      }),
      child: Container(
        height: 40,
        decoration: BoxDecoration(
          color: isActive ? AppCores.azulFundo : const Color(0xFFF0F2F6),
          borderRadius: BorderRadius.circular(AppBorders.pilulas),
          border: Border.all(
            color: isActive ? AppCores.azulFundo : AppCores.outline,
          ),
        ),
        child: Center(
          child: Text(
            label,
            style: TextStyle(
              color: isActive ? AppCores.branco : AppCores.fontes,
              fontSize: 14.0,
              fontWeight: isActive ? FontWeight.w600 : FontWeight.w500,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSubFiltroButton(String label, String value) {
    final isActive = _historicoFiltro == value;
    return GestureDetector(
      onTap: () => setState(() => _historicoFiltro = value),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14.0, vertical: 8.0),
        decoration: BoxDecoration(
          color: isActive ? AppCores.azulFundo : AppCores.branco,
          borderRadius: BorderRadius.circular(20.0),
          border: Border.all(
            color: isActive ? AppCores.azulFundo : AppCores.outline,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isActive ? AppCores.branco : AppCores.fontes,
            fontSize: 12.0,
            fontWeight: isActive ? FontWeight.w600 : FontWeight.w500,
          ),
        ),
      ),
    );
  }

  // ── LISTA ───────────────────────────────────────────────────────────────
  Widget _buildLista() {
    final l10n = AppLocalizations.of(context);
    final isLoading = _ctrl.isLoading;
    final erro = _ctrl.errorMessage;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              _viewMode == 'progresso'
                  ? 'Objetivos em Progresso'
                  : (l10n?.historicoTitulo ?? 'Histórico'),
              style: const TextStyle(
                color: AppCores.fontes,
                fontSize: 16.0,
                fontWeight: FontWeight.bold,
              ),
            ),
            if (_diaSelecionado != null)
              GestureDetector(
                onTap: () => setState(() => _diaSelecionado = null),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10.0,
                    vertical: 5.0,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF0F4F8),
                    borderRadius: BorderRadius.circular(
                      AppBorders.padrao_pequeno,
                    ),
                    border: Border.all(color: AppCores.outline),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        UIcons.boldRounded.cross_small,
                        color: AppCores.fontes,
                        size: 10,
                      ),
                      const SizedBox(width: 4),
                      const Text(
                        'Ver todos',
                        style: TextStyle(
                          color: AppCores.fontes,
                          fontSize: 11.0,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
              )
            else
              Text(
                '(${_objetivosFiltrados.length})',
                style: const TextStyle(
                  color: Color(0xFF8FA3B8),
                  fontSize: 15.0,
                ),
              ),
          ],
        ),
        const SizedBox(height: 16),
        if (isLoading)
          _buildEstadoLoading()
        else if (erro != null)
          _buildEstadoErro(erro)
        else if (_objetivosFiltrados.isEmpty)
          _buildEstadoVazio()
        else
          Column(
            children: _objetivosFiltrados.asMap().entries.map((entry) {
              final isLast = entry.key == _objetivosFiltrados.length - 1;
              return Padding(
                padding: EdgeInsets.only(bottom: isLast ? 0 : 12.0),
                child: _buildCardObjetivo(entry.value),
              );
            }).toList(),
          ),
      ],
    );
  }

  Widget _buildEstadoLoading() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(40.0),
      decoration: BoxDecoration(
        color: AppCores.branco,
        borderRadius: BorderRadius.circular(AppBorders.padrao),
        border: Border.all(color: AppCores.outline),
      ),
      child: const Column(
        children: [
          SizedBox(
            width: 32,
            height: 32,
            child: CircularProgressIndicator(
              color: AppCores.azulFundo,
              strokeWidth: 2.5,
            ),
          ),
          SizedBox(height: 16),
          Text(
            'A carregar os teus objetivos...',
            style: TextStyle(color: Color(0xFF8FA3B8), fontSize: 14.0),
          ),
        ],
      ),
    );
  }

  Widget _buildEstadoErro(String mensagem) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(32.0),
      decoration: BoxDecoration(
        color: AppCores.branco,
        borderRadius: BorderRadius.circular(AppBorders.padrao),
        border: Border.all(color: AppCores.outline),
      ),
      child: Column(
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: const BoxDecoration(
              color: AppCores.erroLoginFundo,
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Icon(
                UIcons.boldRounded.exclamation,
                color: AppCores.erroLogin,
                size: 32,
              ),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            mensagem,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: AppCores.fontes,
              fontSize: 14.0,
              height: 1.4,
            ),
          ),
          const SizedBox(height: 20),
          ElevatedButton.icon(
            onPressed: () => _ctrl.carregarDadosObjetivos(),
            icon: Icon(
              UIcons.boldRounded.rotate_right,
              size: 14,
              color: AppCores.branco,
            ),
            label: const Text(
              'Tentar novamente',
              style: TextStyle(fontSize: 13.0, fontWeight: FontWeight.w600),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppCores.azulFundo,
              foregroundColor: AppCores.branco,
              elevation: 0,
              padding: const EdgeInsets.symmetric(
                horizontal: 18.0,
                vertical: 12.0,
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(AppBorders.padrao_pequeno),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEstadoVazio() {
    String mensagem;
    IconData icone;
    if (_viewMode == 'historico') {
      mensagem = 'Ainda não tens histórico de objetivos.';
      icone = UIcons.boldRounded.time_past;
    } else if (_diaSelecionado != null) {
      mensagem = 'Nenhum objetivo expira neste dia.';
      icone = UIcons.boldRounded.calendar;
    } else {
      mensagem = 'Ainda não tens objetivos em progresso.';
      icone = UIcons.boldRounded.target;
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(40.0),
      decoration: BoxDecoration(
        color: AppCores.branco,
        borderRadius: BorderRadius.circular(AppBorders.padrao),
        border: Border.all(color: AppCores.outline),
      ),
      child: Column(
        children: [
          Icon(icone, color: const Color(0xFFAAB7C4), size: 44),
          const SizedBox(height: 14),
          Text(
            mensagem,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: Color(0xFF8FA3B8),
              fontSize: 14.0,
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCardObjetivo(Map<String, dynamic> obj) {
    final cor = _corObjetivo(obj);
    final isHistorico = _viewMode == 'historico';
    final progresso = (obj['progresso'] as double? ?? 0.0).clamp(0.0, 1.0);
    final avatarColor = obj['avatarColor'] as Color? ?? const Color(0xFF82ADE7);
    final imagem = obj['imagem'] as String?;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16.0),
      decoration: BoxDecoration(
        color: AppCores.branco,
        borderRadius: BorderRadius.circular(AppBorders.padrao),
        border: Border.all(color: AppCores.outline),
      ),
      child: Column(
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (!isHistorico)
                Padding(
                  padding: const EdgeInsets.only(right: 8.0),
                  child: GestureDetector(
                    onTap: () => _confirmarRemocao(obj),
                    child: Icon(
                      UIcons.boldRounded.cross_small,
                      color: const Color(0xFFAAB7C4),
                      size: 18,
                    ),
                  ),
                ),
              _buildBadgeCircle(
                avatarColor: avatarColor,
                imagem: imagem,
                size: 48,
                iconSize: 22,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      obj['titulo']?.toString() ?? 'Badge',
                      style: const TextStyle(
                        color: AppCores.fontes,
                        fontSize: 15.0,
                        fontWeight: FontWeight.w600,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 3),
                    Text(
                      obj['categoria']?.toString() ?? 'Geral',
                      style: const TextStyle(
                        color: Color(0xFF8FA3B8),
                        fontSize: 11.0,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 10),
                    Container(
                      height: 5,
                      decoration: BoxDecoration(
                        color: const Color(0xFFE9ECEF),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: FractionallySizedBox(
                        alignment: Alignment.centerLeft,
                        widthFactor: progresso,
                        child: Container(
                          decoration: BoxDecoration(
                            color: cor,
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        UIcons.boldRounded.calendar,
                        color: const Color(0xFF8FA3B8),
                        size: 11,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        obj['deadline']?.toString() ?? '',
                        style: const TextStyle(
                          color: Color(0xFF8FA3B8),
                          fontSize: 11.0,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 7,
                        height: 7,
                        decoration: BoxDecoration(
                          color: cor,
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 5),
                      Text(
                        _estadoTexto(obj),
                        style: TextStyle(
                          color: cor,
                          fontSize: 12.0,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),
          if (!isHistorico) ...[
            const SizedBox(height: 14),
            const Divider(color: AppCores.outline, height: 1),
            const SizedBox(height: 14),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'SOBRE ESTE BADGE',
                        style: TextStyle(
                          color: AppCores.azulFundo,
                          fontSize: 11.0,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 0.5,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        obj['descricao']?.toString() ??
                            'Sem descrição disponível.',
                        style: const TextStyle(
                          color: AppCores.fontes,
                          fontSize: 12.0,
                          height: 1.4,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                ElevatedButton(
                  onPressed: () => _abrirDetalheBadge(obj),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppCores.azulFundo,
                    foregroundColor: AppCores.branco,
                    elevation: 0,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 18.0,
                      vertical: 10.0,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(
                        AppBorders.padrao_pequeno,
                      ),
                    ),
                  ),
                  child: const Text(
                    'Continuar',
                    style: TextStyle(
                      fontSize: 12.0,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  void _abrirDetalheBadge(Map<String, dynamic> obj) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => BadgeDetalheScreen(badge: obj)),
    );
  }

  // ── BADGE CIRCLES ───────────────────────────────────────────────────────
  Widget _buildBadgeCircle({
    required Color avatarColor,
    String? imagem,
    required double size,
    required double iconSize,
  }) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: avatarColor.withValues(alpha: 0.15),
        shape: BoxShape.circle,
      ),
      clipBehavior: Clip.antiAlias,
      child: (imagem != null && imagem.isNotEmpty)
          ? Image.network(
              imagem,
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) => Center(
                child: Icon(
                  Icons.bolt_rounded,
                  color: avatarColor,
                  size: iconSize,
                ),
              ),
            )
          : Center(
              child: Icon(
                Icons.bolt_rounded,
                color: avatarColor,
                size: iconSize,
              ),
            ),
    );
  }

  Widget _buildMiniBadgeCircle(Map<String, dynamic> badge) {
    final avatarColor =
        badge['avatarColor'] as Color? ?? const Color(0xFF82ADE7);
    final imagem = badge['imagem'] as String?;
    return _buildBadgeCircle(
      avatarColor: avatarColor,
      imagem: imagem,
      size: 28,
      iconSize: 14,
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// CALENDÁRIO MENSAL
// ═══════════════════════════════════════════════════════════════════════════

class _CalendarioMensal extends StatefulWidget {
  final List<Map<String, dynamic>> objetivos;
  final DateTime? diaSelecionado;
  final DateTime hoje;
  final Function(DateTime?) onDiaClick;
  final Function(Map<String, dynamic>) corObjetivo;
  final DateTime? Function(Map<String, dynamic>) parseData;

  const _CalendarioMensal({
    required this.objetivos,
    required this.diaSelecionado,
    required this.hoje,
    required this.onDiaClick,
    required this.corObjetivo,
    required this.parseData,
  });

  @override
  State<_CalendarioMensal> createState() => _CalendarioMensalState();
}

class _CalendarioMensalState extends State<_CalendarioMensal> {
  DateTime _mesVista = DateTime.now();

  DateTime _primeiroDiaDoMes() => DateTime(_mesVista.year, _mesVista.month, 1);

  int _diasNoMes() => DateTime(_mesVista.year, _mesVista.month + 1, 0).day;

  int _diaDaSemanaDoPrimeiroDia() => _primeiroDiaDoMes().weekday % 7;

  void _mudarMes(int delta) {
    setState(() {
      _mesVista = DateTime(_mesVista.year, _mesVista.month + delta);
    });
  }

  List<Map<String, dynamic>> _objetivosDoDia(int dia) {
    final alvo = DateTime(_mesVista.year, _mesVista.month, dia);
    return widget.objetivos.where((o) {
      final d = widget.parseData(o);
      return d != null &&
          d.year == alvo.year &&
          d.month == alvo.month &&
          d.day == alvo.day;
    }).toList();
  }

  Color? _corAgrupada(List<Map<String, dynamic>> objs) {
    if (objs.isEmpty) return null;
    if (objs.any((o) => widget.corObjetivo(o) == AppCores.erroLogin)) {
      return AppCores.erroLogin;
    }
    if (objs.any((o) => widget.corObjetivo(o) == const Color(0xFFE17100))) {
      return const Color(0xFFE17100);
    }
    return AppCores.sucessoLogin;
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            IconButton(
              icon: Icon(
                UIcons.boldRounded.angle_small_left,
                color: AppCores.fontes,
              ),
              onPressed: () => _mudarMes(-1),
            ),
            Text(
              '${_mesesPT[_mesVista.month - 1]} ${_mesVista.year}',
              style: const TextStyle(
                color: AppCores.fontes,
                fontSize: 16.0,
                fontWeight: FontWeight.w600,
              ),
            ),
            IconButton(
              icon: Icon(
                UIcons.boldRounded.angle_small_right,
                color: AppCores.fontes,
              ),
              onPressed: () => _mudarMes(1),
            ),
          ],
        ),
        const SizedBox(height: 16),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: _diasSemana
              .map(
                (dia) => SizedBox(
                  width: 36,
                  child: Text(
                    dia,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      color: Color(0xFF8FA3B8),
                      fontSize: 11.0,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              )
              .toList(),
        ),
        const SizedBox(height: 12),
        GridView.count(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisCount: 7,
          childAspectRatio: 0.85,
          mainAxisSpacing: 6,
          crossAxisSpacing: 6,
          children: _buildDias(),
        ),
      ],
    );
  }

  List<Widget> _buildDias() {
    final List<Widget> dias = [];
    final offset = _diaDaSemanaDoPrimeiroDia();
    final totalDias = _diasNoMes();

    for (int i = 0; i < offset; i++) {
      dias.add(const SizedBox.shrink());
    }

    for (int dia = 1; dia <= totalDias; dia++) {
      final alvo = DateTime(_mesVista.year, _mesVista.month, dia);
      final objs = _objetivosDoDia(dia);
      final isHoje =
          widget.hoje.year == alvo.year &&
          widget.hoje.month == alvo.month &&
          widget.hoje.day == alvo.day;
      final isSelecionado =
          widget.diaSelecionado != null &&
          widget.diaSelecionado!.year == alvo.year &&
          widget.diaSelecionado!.month == alvo.month &&
          widget.diaSelecionado!.day == alvo.day;
      final cor = isSelecionado ? null : _corAgrupada(objs);

      dias.add(
        GestureDetector(
          onTap: () => widget.onDiaClick(alvo),
          child: Container(
            decoration: BoxDecoration(
              color: isSelecionado
                  ? AppCores.azulFundo
                  : isHoje
                  ? const Color(0xFFE9ECEF)
                  : Colors.transparent,
              borderRadius: BorderRadius.circular(AppBorders.padrao_pequeno),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  '$dia',
                  style: TextStyle(
                    color: isSelecionado
                        ? AppCores.branco
                        : cor ?? AppCores.fontes,
                    fontSize: 13.0,
                    fontWeight: isHoje || isSelecionado
                        ? FontWeight.w700
                        : FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 4),
                Container(
                  width: 5,
                  height: 5,
                  decoration: BoxDecoration(
                    color: cor != null
                        ? (isSelecionado ? AppCores.branco : cor)
                        : Colors.transparent,
                    shape: BoxShape.circle,
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return dias;
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// MODAL BADGE PICKER
// ═══════════════════════════════════════════════════════════════════════════

class _BadgePickerModal extends StatefulWidget {
  final List<Map<String, dynamic>> badges;
  final ValueChanged<Map<String, dynamic>> onSelecionar;

  const _BadgePickerModal({required this.badges, required this.onSelecionar});

  @override
  State<_BadgePickerModal> createState() => _BadgePickerModalState();
}

class _BadgePickerModalState extends State<_BadgePickerModal> {
  String _search = '';
  Map<String, dynamic>? _selected;
  String _ordenacao = 'recentes';
  String _areaAtiva = 'Todas';

  List<String> get _areasUnicas {
    final areas = widget.badges
        .map(
          (b) =>
              b['categoria_badge']?.toString() ??
              b['nome_area']?.toString() ??
              '',
        )
        .where((a) => a.isNotEmpty)
        .toSet()
        .toList();
    areas.sort();
    return ['Todas', ...areas];
  }

  List<Map<String, dynamic>> get _filtrados {
    return widget.badges.where((b) {
      final nome = (b['nome_badge']?.toString() ?? '').toLowerCase();
      final area =
          (b['categoria_badge']?.toString() ?? b['nome_area']?.toString() ?? '')
              .toLowerCase();
      final matchesSearch =
          nome.contains(_search.toLowerCase()) ||
          area.contains(_search.toLowerCase());
      final matchesArea =
          _areaAtiva == 'Todas' ||
          (b['categoria_badge']?.toString() ??
                  b['nome_area']?.toString() ??
                  '') ==
              _areaAtiva;
      return matchesSearch && matchesArea;
    }).toList()..sort((a, b) {
      switch (_ordenacao) {
        case 'az':
          return (a['nome_badge']?.toString() ?? '').compareTo(
            b['nome_badge']?.toString() ?? '',
          );
        case 'za':
          return (b['nome_badge']?.toString() ?? '').compareTo(
            a['nome_badge']?.toString() ?? '',
          );
        case 'antigos':
          final idA = int.tryParse(a['id_badge']?.toString() ?? '0') ?? 0;
          final idB = int.tryParse(b['id_badge']?.toString() ?? '0') ?? 0;
          return idA.compareTo(idB);
        case 'recentes':
        default:
          final idA = int.tryParse(a['id_badge']?.toString() ?? '0') ?? 0;
          final idB = int.tryParse(b['id_badge']?.toString() ?? '0') ?? 0;
          return idB.compareTo(idA);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(
        horizontal: 16.0,
        vertical: 24.0,
      ),
      child: Container(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.85,
          maxWidth: 560,
        ),
        decoration: const BoxDecoration(
          color: AppCores.branco,
          borderRadius: BorderRadius.all(Radius.circular(20.0)),
        ),
        child: ClipRRect(
          borderRadius: const BorderRadius.all(Radius.circular(20.0)),
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.only(top: 12.0, bottom: 8.0),
                child: Container(
                  width: 40,
                  height: 5,
                  decoration: BoxDecoration(
                    color: AppCores.outline.withValues(alpha: 0.6),
                    borderRadius: BorderRadius.circular(999),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Escolhe um Badge',
                      style: TextStyle(
                        color: AppCores.fontes,
                        fontSize: 18.0,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    GestureDetector(
                      onTap: () => Navigator.of(context).pop(),
                      child: Container(
                        width: 34,
                        height: 34,
                        decoration: const BoxDecoration(
                          color: Color(0xFFF0F4F8),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.close,
                          color: Color(0xFF666666),
                          size: 18,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20.0),
                child: _buildSearchBar(),
              ),
              const SizedBox(height: 12),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20.0),
                child: SizedBox(
                  height: 34,
                  child: ListView.separated(
                    scrollDirection: Axis.horizontal,
                    itemCount: _areasUnicas.length,
                    separatorBuilder: (_, _) => const SizedBox(width: 8),
                    itemBuilder: (context, index) {
                      final area = _areasUnicas[index];
                      final isActive = _areaAtiva == area;
                      return GestureDetector(
                        onTap: () => setState(() => _areaAtiva = area),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12.0,
                            vertical: 6.0,
                          ),
                          decoration: BoxDecoration(
                            color: isActive
                                ? AppCores.azulFundo
                                : AppCores.branco,
                            borderRadius: BorderRadius.circular(20.0),
                            border: Border.all(
                              color: isActive
                                  ? AppCores.azulFundo
                                  : AppCores.outline,
                            ),
                          ),
                          child: Text(
                            area == 'Todas' ? 'Todas As Áreas' : area,
                            style: TextStyle(
                              color: isActive
                                  ? AppCores.branco
                                  : AppCores.fontes,
                              fontSize: 12.0,
                              fontWeight: isActive
                                  ? FontWeight.w600
                                  : FontWeight.w500,
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ),
              const SizedBox(height: 12),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        '${_filtrados.length} ${_filtrados.length == 1 ? 'badge encontrado' : 'badges encontrados'}',
                        style: const TextStyle(
                          color: Color(0xFF8FA3B8),
                          fontSize: 12.0,
                          fontWeight: FontWeight.w500,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(width: 8),
                    _buildOrdenacaoDropdown(),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              Expanded(
                child: _filtrados.isEmpty
                    ? _buildEstadoVazio()
                    : GridView.builder(
                        padding: const EdgeInsets.symmetric(horizontal: 20.0),
                        gridDelegate:
                            const SliverGridDelegateWithFixedCrossAxisCount(
                              crossAxisCount: 3,
                              mainAxisSpacing: 16,
                              crossAxisSpacing: 12,
                              childAspectRatio: 0.85,
                            ),
                        itemCount: _filtrados.length,
                        itemBuilder: (context, index) {
                          final badge = _filtrados[index];
                          return GestureDetector(
                            onTap: () => setState(() => _selected = badge),
                            child: _buildBadgeGridCard(badge),
                          );
                        },
                      ),
              ),
              Container(
                padding: const EdgeInsets.all(20.0),
                decoration: BoxDecoration(
                  color: AppCores.branco,
                  border: Border(
                    top: BorderSide(color: AppCores.outline.withValues(alpha: 0.5)),
                  ),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => Navigator.of(context).pop(),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: AppCores.fontes,
                          side: const BorderSide(color: Color(0xFFCED4DA)),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10.0),
                          ),
                          minimumSize: const Size(double.infinity, 44),
                        ),
                        child: Text(l10n?.cancelar ?? 'Cancelar'),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: _selected != null
                            ? () {
                                widget.onSelecionar(_selected!);
                                Navigator.of(context).pop();
                              }
                            : null,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppCores.azulFundo,
                          foregroundColor: AppCores.branco,
                          elevation: 0,
                          disabledBackgroundColor: const Color(0xFFAAB7C4),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10.0),
                          ),
                          minimumSize: const Size(double.infinity, 44),
                        ),
                        child: Text(
                          _selected != null
                              ? 'Confirmar — ${_selected!['nome_badge']}'
                              : 'Seleciona um badge',
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSearchBar() {
    final l10n = AppLocalizations.of(context);
    return Container(
      height: 44,
      padding: const EdgeInsets.symmetric(horizontal: 14.0),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(12.0),
        border: Border.all(color: AppCores.outline),
      ),
      child: Row(
        children: [
          Icon(
            UIcons.boldRounded.search,
            color: const Color(0xFFAAB7C4),
            size: 16,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: TextField(
              onChanged: (value) => setState(() => _search = value),
              decoration: InputDecoration(
                hintText: l10n?.pesquisarBadge ?? 'Pesquisar Badge...',
                hintStyle: const TextStyle(
                  color: Color(0xFF8FA3B8),
                  fontSize: 13.0,
                ),
                border: InputBorder.none,
                contentPadding: EdgeInsets.zero,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOrdenacaoDropdown() {
    return PopupMenuButton<String>(
      onSelected: (value) => setState(() => _ordenacao = value),
      itemBuilder: (context) => [
        const PopupMenuItem(value: 'recentes', child: Text('Mais recentes')),
        const PopupMenuItem(value: 'antigos', child: Text('Mais antigos')),
        const PopupMenuItem(value: 'az', child: Text('A-Z')),
        const PopupMenuItem(value: 'za', child: Text('Z-A')),
      ],
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 8.0),
        decoration: BoxDecoration(
          color: const Color(0xFFF8FAFC),
          border: Border.all(color: AppCores.outline),
          borderRadius: BorderRadius.circular(8.0),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Mais recentes: ${_ordenacaoLabel(_ordenacao)}',
              style: const TextStyle(
                color: AppCores.fontes,
                fontSize: 12.0,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(width: 4),
            const Icon(
              Icons.keyboard_arrow_down,
              color: AppCores.fontes,
              size: 16,
            ),
          ],
        ),
      ),
    );
  }

  String _ordenacaoLabel(String value) {
    switch (value) {
      case 'recentes':
        return 'Mais recentes';
      case 'antigos':
        return 'Mais antigos';
      case 'az':
        return 'A-Z';
      case 'za':
        return 'Z-A';
      default:
        return 'Ordenar';
    }
  }

  Widget _buildEstadoVazio() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(UIcons.boldRounded.search, color: AppCores.outline, size: 40),
          const SizedBox(height: 12),
          const Text(
            'Nenhum badge encontrado',
            style: TextStyle(color: AppCores.fontes, fontSize: 14.0),
          ),
          const SizedBox(height: 4),
          const Text(
            'Tenta ajustar os filtros ou a pesquisa.',
            style: TextStyle(color: Color(0xFF8FA3B8), fontSize: 12.0),
          ),
        ],
      ),
    );
  }

  Widget _buildBadgeGridCard(Map<String, dynamic> badge) {
    final isSelected =
        _selected != null && _selected!['id_badge'] == badge['id_badge'];
    final avatarColor =
        badge['avatarColor'] as Color? ?? const Color(0xFF82ADE7);
    final imagem = badge['imagem'] as String?;
    final pontos = badge['pontos_badge'] ?? badge['pontos'] ?? 0;

    return Container(
      padding: const EdgeInsets.all(10.0),
      decoration: BoxDecoration(
        color: AppCores.branco,
        borderRadius: BorderRadius.circular(AppBorders.padrao),
        border: Border.all(
          color: isSelected ? AppCores.azulFundo : AppCores.outline,
          width: isSelected ? 2 : 1,
        ),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              color: avatarColor.withValues(alpha: 0.15),
              shape: BoxShape.circle,
            ),
            clipBehavior: Clip.antiAlias,
            child: (imagem != null && imagem.isNotEmpty)
                ? Image.network(
                    imagem,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) => Center(
                      child: Icon(
                        Icons.bolt_rounded,
                        color: avatarColor,
                        size: 24,
                      ),
                    ),
                  )
                : Center(
                    child: Icon(
                      Icons.bolt_rounded,
                      color: avatarColor,
                      size: 24,
                    ),
                  ),
          ),
          const SizedBox(height: 8),
          Text(
            badge['nome_badge']?.toString() ?? 'Badge',
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: AppCores.fontes,
              fontSize: 12.0,
              fontWeight: FontWeight.w600,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 2),
          Text(
            '$pontos pts',
            style: const TextStyle(color: Color(0xFF8FA3B8), fontSize: 10.0),
          ),
        ],
      ),
    );
  }
}
