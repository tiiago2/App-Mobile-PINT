import 'package:flutter/material.dart';
import 'package:uicons/uicons.dart';
import '../../variaveis/variaveis.dart';
import 'galeria_badges_modular.dart';
import '../../pages/badge_detalhe.dart';

class BadgeItemComEstadoWrapper extends StatelessWidget {
  final Map<String, dynamic> badge;

  const BadgeItemComEstadoWrapper({super.key, required this.badge});

  Widget _buildEstadoOverlay(String estado) {
    if (estado == 'emProgresso' || estado == 'disponivel') {
      return const SizedBox();
    }

    Color corFundo;
    IconData icone;
    
    switch (estado) {
      case 'conquistados':
        corFundo = const Color(0xFF009966);
        icone = UIcons.boldRounded.check;
        break;
      case 'recusados':
        corFundo = const Color(0xFFC41230);
        icone = UIcons.boldRounded.cross_small;
        break;
      case 'pendentes':
        corFundo = const Color(0xFFF8AA0B);
        icone = UIcons.boldRounded.clock;
        break;
      case 'expirados':
        corFundo = AppCores.erroLogin;
        icone = UIcons.boldRounded.time_past;
        break;
      case 'bloqueados':
        corFundo = const Color(0xFFADADAD);
        icone = UIcons.boldRounded.lock;
        break;
      default:
        return const SizedBox();
    }

    return Container(
      width: 22.0,
      height: 22.0,
      decoration: BoxDecoration(
        color: corFundo,
        shape: BoxShape.circle,
      ),
      child: Icon(
        icone,
        color: Colors.white,
        size: 12.0,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final String? estado = badge['estado'];
    final progresso = badge['progresso'];
    final double progressoNormalizado;

    if (progresso is num) {
      final valor = progresso > 1
          ? progresso.toDouble() / 100
          : progresso.toDouble();

      progressoNormalizado = valor.clamp(0.0, 1.0).toDouble();
    } else {
      progressoNormalizado = 0.0;
    }

    Color? imageColor;
    BlendMode? imageBlendMode;

    if (estado != null) {
      if (estado == 'bloqueados') {
        imageColor = Colors.grey;
        imageBlendMode = BlendMode.saturation;
      } else if (estado == 'pendentes' || estado == 'recusados' || estado == 'expirados' || estado == 'emProgresso') {
        imageColor = Colors.white.withOpacity(0.5);
        imageBlendMode = BlendMode.lighten;
      }
    }

    Widget content = BadgeItemModular(
      badge: badge,
      imageColor: imageColor,
      imageBlendMode: imageBlendMode,
    );

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
                content,
                if (estado != null &&
                    estado != 'emProgresso' &&
                    estado != 'disponivel')
                  Positioned(
                    top: 54.0, // 76 (imagem) - 22 (icone)
                    left: 56.0, // puxar ligeiramente para a direita
                    child: _buildEstadoOverlay(estado),
                  ),
              ],
            ),
            if (estado == 'emProgresso')
              Padding(
                padding: const EdgeInsets.only(top: 6.0),
                child: Container(
                  width: double.infinity,
                  height: 4.0,
                  alignment: Alignment.centerLeft,
                  decoration: BoxDecoration(
                    color: const Color(0xFFD9D9D9),
                    borderRadius: BorderRadius.circular(2.0),
                  ),
                  child: FractionallySizedBox(
                    alignment: Alignment.centerLeft,
                    widthFactor: progressoNormalizado,
                    child: Container(
                      decoration: BoxDecoration(
                        color: const Color(0xFF62C884),
                        borderRadius: BorderRadius.circular(2.0),
                      ),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class GaleriaBadgesComEstado extends StatelessWidget {
  final List<Map<String, dynamic>> badges;
  final bool centralizar;

  const GaleriaBadgesComEstado({
    super.key,
    required this.badges,
    this.centralizar = false,
  });

  @override
  Widget build(BuildContext context) {
    if (badges.isEmpty) {
      return const Text(
        'Nenhum badge disponível nesta secção.',
        style: TextStyle(color: AppCores.fontes, fontSize: 12.0),
      );
    }

    return Container(
      width: double.infinity,
      alignment: centralizar ? Alignment.center : Alignment.centerLeft,
      child: Wrap(
        alignment: centralizar ? WrapAlignment.center : WrapAlignment.start,
        spacing: 16.0,
        runSpacing: 16.0,
        children: badges.map((badge) => BadgeItemComEstadoWrapper(badge: badge)).toList(),
      ),
    );
  }
}
