import 'package:flutter/material.dart';
import '../../variaveis/variaveis.dart';
import '../../pages/badge_detalhe.dart';

class GaleriaBadgesModular extends StatelessWidget {
  final List<Map<String, dynamic>> badges;

  const GaleriaBadgesModular({
    super.key,
    required this.badges,
  });

  @override
  Widget build(BuildContext context) {
    if (badges.isEmpty) {
      return const Text(
        'Nenhum badge disponível nesta secção.',
        style: TextStyle(color: AppCores.fontes, fontSize: 12.0),
      );
    }

    return Wrap(
      spacing: 16.0,
      runSpacing: 16.0,
      children: badges.map((badge) => BadgeItemModular(badge: badge)).toList(),
    );
  }
}

class BadgeItemModular extends StatelessWidget {
  final Map<String, dynamic> badge;
  final Color? imageColor;
  final BlendMode? imageBlendMode;

  const BadgeItemModular({
    super.key,
    required this.badge,
    this.imageColor,
    this.imageBlendMode,
  });

  // Placeholder colorido com a inicial do badge
  Widget _buildPlaceholder() {
    final titulo = (badge['titulo'] as String?) ?? '';
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
      titulo.isEmpty ? 0 : titulo.codeUnits.fold(0, (a, b) => a + b) % paleta.length
    ];
    final letra = titulo.isNotEmpty ? titulo[0].toUpperCase() : '?';

    return ClipOval(
      child: Container(
        width: 76,
        height: 76,
        color: cor,
        child: Center(
          child: Text(
            letra,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 28,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final bool isEspecial = badge['especial'] == true || badge['especial'] == '1';
    final imagem = badge['imagem'];
    final hasNetworkImage = imagem is String &&
        (imagem.startsWith('http://') || imagem.startsWith('https://'));

    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => BadgeDetalheScreen(badge: badge),
          ),
        );
      },
      child: SizedBox(
        width: 76.0,
        child: Column(
          children: [
            Stack(
              clipBehavior: Clip.none,
              children: [
                Container(
                  width: 76.0,
                  height: 76.0,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: isEspecial
                        ? Border.all(
                            color: const Color(0xFFF8AA0B), // Cor de ouro do design
                            width: 2.0,
                          )
                        : null,
                  ),
                  child: hasNetworkImage 
                      ? ClipOval( 
                          child: Image.network(
                            imagem,
                            fit: BoxFit.cover,
                            color: imageColor,
                            colorBlendMode: imageBlendMode,
                          ),
                        )
                      : _buildPlaceholder(),
                ),
                if (isEspecial)
                  Positioned(
                    top: 0.0,
                    left: 0.0,
                    child: Container(
                      width: 22.0,
                      height: 22.0,
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
                        size: 14.0,
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 8.0),
            Text(
              badge['titulo'] ?? '',
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: AppCores.fontes,
                fontSize: 12.0,
                fontWeight: FontWeight.w500,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }
}
