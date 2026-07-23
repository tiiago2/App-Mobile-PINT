import 'package:flutter/material.dart';
import '../variaveis/variaveis.dart';
import '../idiomas/app_localizations.dart';

/// Ecrã de detalhe de um badge.
///
/// Recebe [badge] como [Map<String, dynamic>] com campos de qualquer origem
/// (galeria, badges pessoais, candidaturas, perfil, sugeridos).
/// Não depende de nenhum controller nem de ligação à base de dados.
///
/// Campos lidos (com fallback automático):
///   titulo / title / nome_badge
///   descricao / descricao_badge
///   areaNome / area / categoria / category / subtitulo
///   nivelNome / nivel
///   pontos / points
///   validadeDias
///   especial  (bool | '1' | 1)
///   imagem    (URL de rede)
///   icon      (IconData)
///   avatarColor (Color)
///   estado / status  (string: conquistados, pendentes, emProgresso, recusados, expirados, bloqueados, disponivel)
///   progresso / progressPercentage (0–100)
class BadgeDetalheScreen extends StatelessWidget {
  final Map<String, dynamic> badge;

  const BadgeDetalheScreen({super.key, required this.badge});

  // ── Helpers de leitura ────────────────────────────────────────────────────

  String get _titulo {
    for (final k in ['titulo', 'title', 'nome_badge']) {
      final v = badge[k];
      if (v is String && v.trim().isNotEmpty) return v.trim();
    }
    return 'Badge';
  }

  String get _descricao {
    for (final k in ['descricao', 'descricao_badge']) {
      final v = badge[k];
      if (v is String && v.trim().isNotEmpty) return v.trim();
    }
    return '';
  }

  String get _area {
    for (final k in ['areaNome', 'area', 'categoria', 'category', 'subtitulo']) {
      final v = badge[k];
      if (v is String && v.trim().isNotEmpty) return v.trim();
    }
    return '';
  }

  String get _nivel {
    for (final k in ['nivelNome', 'nivel']) {
      final v = badge[k];
      if (v is String && v.trim().isNotEmpty) return v.trim();
    }
    return '';
  }

  int get _pontos {
    for (final k in ['pontos', 'points']) {
      final v = badge[k];
      if (v is num) return v.toInt();
    }
    return 0;
  }

  int get _validadeDias {
    final v = badge['validadeDias'];
    return v is num ? v.toInt() : 0;
  }

  bool get _especial {
    final v = badge['especial'];
    return v == true || v == '1' || v == 1;
  }

  String? get _imagem {
    final v = badge['imagem'];
    if (v is String && v.trim().isNotEmpty) return v.trim();
    return null;
  }

  IconData? get _icon => badge['icon'] as IconData?;

  Color get _avatarColor {
    final v = badge['avatarColor'];
    return v is Color ? v : AppCores.azulFundo;
  }

  String get _estadoNormalizado {
    for (final k in ['estado', 'status']) {
      final v = badge[k];
      if (v is String && v.trim().isNotEmpty) return v.trim().toLowerCase();
    }
    return '';
  }

  int get _progresso {
    for (final k in ['progresso', 'progressPercentage']) {
      final v = badge[k];
      if (v is num) return v.toInt();
    }
    return 0;
  }

  // ── Avatar ────────────────────────────────────────────────────────────────

  Widget _buildAvatar({double size = 108}) {
    final imagem = _imagem;
    final hasNetworkImage = imagem != null &&
        (imagem.startsWith('http://') || imagem.startsWith('https://'));
    final icon = _icon;

    Widget inner;
    if (hasNetworkImage) {
      inner = Image.network(
        imagem,
        width: size,
        height: size,
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) => _placeholderAvatar(size),
      );
    } else if (icon != null) {
      inner = Container(
        width: size,
        height: size,
        color: _avatarColor.withOpacity(0.15),
        child: Center(
          child: Icon(icon, color: _avatarColor, size: size * 0.42),
        ),
      );
    } else {
      inner = _placeholderAvatar(size);
    }

    return Stack(
      clipBehavior: Clip.none,
      children: [
        Container(
          width: size,
          height: size,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: _especial
                ? Border.all(color: const Color(0xFFF8AA0B), width: 3)
                : Border.all(color: AppCores.outline),
          ),
          clipBehavior: Clip.antiAlias,
          child: inner,
        ),
        // Estrela dourada nos badges especiais – mesmo padrão de galeria_badges_modular.dart
        if (_especial)
          Positioned(
            top: -2,
            left: -2,
            child: Container(
              width: 24,
              height: 24,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFFFFDF3E), Color(0xFFF8AA0B)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.15),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: const Icon(Icons.star_rounded, color: Colors.white, size: 14),
            ),
          ),
      ],
    );
  }

  // Placeholder colorido com inicial – mesmo padrão de galeria_badges_modular.dart
  Widget _placeholderAvatar(double size) {
    const List<Color> paleta = [
      Color(0xFF4F8EF7), Color(0xFF62C884), Color(0xFFF8AA0B),
      Color(0xFFE96A6A), Color(0xFF9B6AF7), Color(0xFF00BFAE),
      Color(0xFFFF7043), Color(0xFF26A69A),
    ];
    final cor = paleta[
      _titulo.isEmpty ? 0 : _titulo.codeUnits.fold(0, (a, b) => a + b) % paleta.length
    ];
    return Container(
      width: size,
      height: size,
      color: cor,
      alignment: Alignment.center,
      child: Text(
        _titulo.isNotEmpty ? _titulo[0].toUpperCase() : '?',
        style: TextStyle(
          color: Colors.white,
          fontSize: size * 0.37,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  // ── Meta chip ─────────────────────────────────────────────────────────────

  Widget _meta(IconData icon, String texto) {
    if (texto.isEmpty) return const SizedBox.shrink();
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration: BoxDecoration(
        color: AppCores.branco,
        borderRadius: BorderRadius.circular(AppBorders.loginCampo),
        border: Border.all(color: AppCores.outline),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 15, color: AppCores.azulFundo),
          const SizedBox(width: 6),
          Text(
            texto,
            style: const TextStyle(
              color: AppCores.fontes,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  // ── Secção Hero ───────────────────────────────────────────────────────────

  Widget _buildHero(AppLocalizations l10n) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppCores.fundo2,
        borderRadius: BorderRadius.circular(AppBorders.padrao),
        border: Border.all(color: AppCores.outline),
      ),
      child: Column(
        children: [
          _buildAvatar(),
          const SizedBox(height: 16),
          Text(
            _titulo,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: AppCores.fontes,
              fontSize: 24,
              fontWeight: FontWeight.w700,
            ),
          ),
          if (_descricao.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(
              _descricao,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: AppCores.fontes.withOpacity(0.75),
                fontSize: 14,
                height: 1.45,
              ),
            ),
          ],
          const SizedBox(height: 16),
          Wrap(
            alignment: WrapAlignment.center,
            spacing: 8,
            runSpacing: 8,
            children: [
              if (_pontos > 0)
                _meta(Icons.school_outlined, '$_pontos ${l10n.pts}'),
              if (_nivel.isNotEmpty)
                _meta(Icons.signal_cellular_alt_rounded, _nivel),
              if (_area.isNotEmpty)
                _meta(Icons.work_outline_rounded, _area),
              _meta(
                _especial ? Icons.star_rounded : Icons.badge_outlined,
                _especial ? l10n.especial : l10n.normal,
              ),
              if (_validadeDias > 0)
                _meta(Icons.event_outlined, '$_validadeDias ${l10n.dias}'),
            ],
          ),
        ],
      ),
    );
  }

  // ── Secção Estado ─────────────────────────────────────────────────────────

  Widget? _buildEstadoCard(AppLocalizations l10n) {
    final estado = _estadoNormalizado;
    if (estado.isEmpty) return null;

    Color cor;
    Color fundo;
    IconData icone;
    String titulo;
    String descricao;

    if (estado.contains('conquist') || estado.contains('aprovado')) {
      cor = const Color(0xFF009966);
      fundo = const Color(0xFFEDF9F3);
      icone = Icons.check_rounded;
      titulo = l10n.badgeConquistado;
      descricao = l10n.badgeConquistadoDesc;
    } else if (estado.contains('pendente') || estado.contains('pending')) {
      cor = const Color(0xFFF59E0B);
      fundo = const Color(0xFFFFF8E7);
      icone = Icons.schedule_rounded;
      titulo = l10n.candidaturaAnalise;
      descricao = l10n.candidaturaAnaliseDesc;
    } else if (estado.contains('progresso') || estado.contains('progress')) {
      cor = AppCores.azulFundo;
      fundo = const Color(0xFFF0F5FB);
      icone = Icons.edit_document;
      titulo = l10n.candidaturaProgresso;
      descricao = '$_progresso% ${l10n.completo}';
    } else if (estado.contains('recusado')) {
      cor = const Color(0xFFD42A2A);
      fundo = const Color(0xFFFFF1F1);
      icone = Icons.close_rounded;
      titulo = l10n.candidaturaRecusada;
      descricao = l10n.candidaturaRecusadaDesc;
    } else if (estado.contains('expir')) {
      cor = const Color(0xFFC62828);
      fundo = const Color(0xFFFFF1F1);
      icone = Icons.history_toggle_off_rounded;
      titulo = l10n.badgeExpirado;
      descricao = l10n.badgeExpiradoDesc;
    } else if (estado.contains('bloqueado') || estado.contains('disponi')) {
      cor = const Color(0xFF6B7280);
      fundo = const Color(0xFFF3F4F6);
      icone = Icons.lock_outline_rounded;
      titulo = l10n.badgeDisponivel;
      descricao = l10n.badgeDisponivelDesc;
    } else {
      return null;
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: fundo,
        borderRadius: BorderRadius.circular(AppBorders.padrao),
        border: Border.all(color: cor.withOpacity(0.35)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(color: cor, shape: BoxShape.circle),
                child: Icon(icone, color: Colors.white, size: 21),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      titulo,
                      style: TextStyle(
                        color: cor,
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      descricao,
                      style: const TextStyle(
                        color: AppCores.fontes,
                        fontSize: 13,
                        height: 1.4,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          if (estado.contains('progresso') || estado.contains('progress')) ...[
            const SizedBox(height: 14),
            ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: (_progresso.clamp(0, 100)) / 100,
                minHeight: 8,
                backgroundColor: AppCores.outline,
                color: cor,
              ),
            ),
          ],
        ],
      ),
    );
  }

  // ── Secção Requisitos (placeholder) ───────────────────────────────────────

  Widget _buildRequisitosPlaceholder(AppLocalizations l10n) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppCores.fundo2,
        borderRadius: BorderRadius.circular(AppBorders.loginCampo),
        border: Border.all(color: AppCores.outline),
      ),
      child: Row(
        children: [
          Icon(
            Icons.info_outline_rounded,
            size: 18,
            color: AppCores.fontes.withOpacity(0.5),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              l10n.requisitosPlaceholder,
              style: TextStyle(
                color: AppCores.fontes.withOpacity(0.6),
                fontSize: 13,
                height: 1.4,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── Build ─────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final estadoCard = _buildEstadoCard(l10n);

    return Scaffold(
      backgroundColor: AppCores.branco,
      appBar: AppBar(
        backgroundColor: AppCores.branco,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          tooltip: l10n.voltar,
          onPressed: () => Navigator.of(context).maybePop(),
          icon: const Icon(
            Icons.arrow_back_ios_new_rounded,
            color: AppCores.fontes,
            size: AppTamanhos.iconeNavegacao,
          ),
        ),
        titleSpacing: 0,
        title: Text(
          l10n.detalheBadge,
          style: const TextStyle(
            color: AppCores.fontes,
            fontSize: AppTamanhos.titulo,
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(
          AppTamanhos.margemEcra,
          8,
          AppTamanhos.margemEcra,
          32,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _buildHero(l10n),
            if (estadoCard != null) ...[
              const SizedBox(height: 16),
              estadoCard,
            ],
            const SizedBox(height: 24),
            Text(
              l10n.requisitosEvidencias,
              style: const TextStyle(
                color: AppCores.fontes,
                fontSize: 18,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 12),
            _buildRequisitosPlaceholder(l10n),
          ],
        ),
      ),
    );
  }
}
