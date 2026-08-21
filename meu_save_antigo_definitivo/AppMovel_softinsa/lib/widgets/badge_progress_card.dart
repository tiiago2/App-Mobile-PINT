import 'package:flutter/material.dart';
import 'package:uicons/uicons.dart';
import '../variaveis/variaveis.dart';
import '../pages/badge_detalhe.dart';

/// Card de badge baseado no design Figma – usado na aba "Sugeridos" e noutras
/// páginas onde se queira mostrar o progresso de um badge específico.
///
/// Parâmetros obrigatórios:
///   [titulo]          – Nome do badge
///   [categoria]       – Área / categoria (ex: "Low Code")
///   [pontos]          – Pontos que o badge vale
///   [avatarColor]     – Cor base do avatar quando não há imagem de rede
///   [progressoPercent] – Progresso de 0 a 100
///
/// Parâmetros opcionais:
///   [icon]    – IconData a mostrar no centro do avatar (ignorado se [imagem] for válido)
///   [imagem]  – URL de imagem de rede (tem prioridade sobre [icon])
///   [especial] – Mostra a estrela dourada no canto do avatar (default: false)
class BadgeProgressCard extends StatelessWidget {
  final String titulo;
  final String categoria;
  final int pontos;
  final IconData? icon;
  final String? imagem;
  final Color avatarColor;
  final int progressoPercent;
  final bool especial;

  const BadgeProgressCard({
    super.key,
    required this.titulo,
    required this.categoria,
    required this.pontos,
    this.icon,
    this.imagem,
    required this.avatarColor,
    required this.progressoPercent,
    this.especial = false,
  });

  // ---------------------------------------------------------------------------
  // Avatar: rede → ícone → placeholder colorido com inicial
  // ---------------------------------------------------------------------------
  Widget _buildAvatar() {
    final hasNetworkImage = imagem != null &&
        (imagem!.startsWith('http://') || imagem!.startsWith('https://'));

    Widget innerContent;

    if (hasNetworkImage) {
      innerContent = ClipOval(
        child: Image.network(
          imagem!,
          width: 82,
          height: 82,
          fit: BoxFit.cover,
        ),
      );
    } else if (icon != null) {
      innerContent = Container(
        width: 82,
        height: 82,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: avatarColor.withValues(alpha: 0.15),
          border: especial
              ? Border.all(color: const Color(0xFFF8AA0B), width: 2.0)
              : null,
        ),
        child: Center(
          child: Icon(icon, color: avatarColor, size: 36.0),
        ),
      );
    } else {
      // Placeholder colorido com inicial – mesma lógica de galeria_badges_modular.dart
      const List<Color> paleta = [
        Color(0xFF4F8EF7),
        Color(0xFF62C884),
        Color(0xFFF8AA0B),
        Color(0xFFE96A6A),
        Color(0xFF9B6AF7),
        Color(0xFF00BFAE),
        Color(0xFFFF7043),
        Color(0xFF26A69A),
      ];
      final cor = paleta[
        titulo.isEmpty
            ? 0
            : titulo.codeUnits.fold(0, (a, b) => a + b) % paleta.length
      ];
      innerContent = ClipOval(
        child: Container(
          width: 82,
          height: 82,
          color: cor,
          child: Center(
            child: Text(
              titulo.isNotEmpty ? titulo[0].toUpperCase() : '?',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 32,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),
      );
    }

    // Estrela dourada no canto – mesma lógica de galeria_badges_modular.dart
    return Stack(
      clipBehavior: Clip.none,
      children: [
        SizedBox(width: 82, height: 82, child: innerContent),
        if (especial)
          Positioned(
            top: -2.0,
            left: -2.0,
            child: Container(
              width: 20.0,
              height: 20.0,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFFFFDF3E), Color(0xFFF8AA0B)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.15),
                    blurRadius: 4.0,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: const Icon(
                Icons.star_rounded,
                color: Colors.white,
                size: 12.0,
              ),
            ),
          ),
      ],
    );
  }

  // ---------------------------------------------------------------------------
  // Points pill – mesmo visual de BadgeCard em candidaturas.dart
  // ---------------------------------------------------------------------------
  Widget _buildPointsPill() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10.0, vertical: 5.0),
      decoration: BoxDecoration(
        color: AppCores.azulFundo,
        borderRadius: BorderRadius.circular(50),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            UIcons.boldRounded.graduation_cap,
            color: Colors.white,
            size: 12.0,
          ),
          const SizedBox(width: 5.0),
          Text(
            '$pontos pts',
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 11.0,
            ),
          ),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Build
  // ---------------------------------------------------------------------------
  @override
  Widget build(BuildContext context) {
    final progress = (progressoPercent.clamp(0, 100)) / 100.0;
    final badgeMap = {
      'titulo': titulo,
      'categoria': categoria,
      'pontos': pontos,
      'icon': icon,
      'imagem': imagem,
      'avatarColor': avatarColor,
      'progresso': progressoPercent,
      'especial': especial,
      'estado': 'emProgresso',
    };

    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => BadgeDetalheScreen(badge: badgeMap),
          ),
        );
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14.0, vertical: 16.0),
        decoration: BoxDecoration(
          color: AppCores.branco,
          borderRadius: BorderRadius.circular(AppBorders.padrao),
          border: Border.all(
            color: AppCores.outline,
            width: AppBorders.espessuraPrincipal,
          ),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Avatar ──────────────────────────────────────────────────────────
            _buildAvatar(),
            const SizedBox(width: 16.0),
            // ── Conteúdo direito ─────────────────────────────────────────────
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Título + categoria + pontos
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              titulo,
                              style: const TextStyle(
                                fontSize: 15.0,
                                fontWeight: FontWeight.w600,
                                color: AppCores.fontes,
                              ),
                            ),
                            const SizedBox(height: 4.0),
                            Text(
                              categoria,
                              style: TextStyle(
                                fontSize: 13.0,
                                color: AppCores.fontes.withValues(alpha: 0.5),
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 8.0),
                      _buildPointsPill(),
                    ],
                  ),
                  const SizedBox(height: 18.0),
                  // Barra de progresso
                  ClipRRect(
                    borderRadius: BorderRadius.circular(3.0),
                    child: LinearProgressIndicator(
                      value: progress,
                      backgroundColor: AppCores.outline,
                      valueColor: const AlwaysStoppedAnimation<Color>(
                        AppCores.azulFundo,
                      ),
                      minHeight: 6.0,
                    ),
                  ),
                  const SizedBox(height: 6.0),
                  Text(
                    '$progressoPercent% completo',
                    style: TextStyle(
                      fontSize: 11.0,
                      color: AppCores.fontes.withValues(alpha: 0.5),
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
