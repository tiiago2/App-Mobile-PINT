import 'package:flutter/material.dart';
import '../../variaveis/variaveis.dart';
import '../../pages/badge_detalhe.dart';
import '../../controllers/galeria_controller.dart';

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

  final bool enableTap;
  final VoidCallback? onTap;

  const BadgeItemModular({
    super.key,
    required this.badge,
    this.imageColor,
    this.imageBlendMode,
    this.enableTap = true,
    this.onTap,
  });

  // Placeholder padrão para avatar do badge quando offline ou sem imagem
  Widget _buildPlaceholder() {
    final avatarColor = badge['avatarColor'] is Color
        ? badge['avatarColor'] as Color
        : const Color(0xFF39639C);
    final icon = badge['icon'] as IconData? ?? Icons.bolt_rounded;

    return ClipOval(
      child: Container(
        width: 76,
        height: 76,
        color: avatarColor.withValues(alpha: 0.15),
        child: Center(
          child: Icon(
            icon,
            color: avatarColor,
            size: 34,
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

    final itemContent = SizedBox(
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
                          errorBuilder: (context, error, stackTrace) => _buildPlaceholder(),
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
    );

    if (!enableTap) return itemContent;

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap ?? () async {
        await Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => BadgeDetalheScreen(badge: badge),
          ),
        );
        GaleriaController.instance.carregarDados();
      },
      child: itemContent,
    );
  }
}
