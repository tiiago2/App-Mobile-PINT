import 'package:flutter/material.dart';
import '../../variaveis/variaveis.dart';
import '../badge_progress_card.dart';

class AbaSugeridos extends StatelessWidget {
  final List<Map<String, dynamic>> sugeridos;

  const AbaSugeridos({super.key, required this.sugeridos});

  @override
  Widget build(BuildContext context) {
    if (sugeridos.isEmpty) {
      return Container(
        height: 200,
        alignment: Alignment.center,
        child: const Text(
          'Sem sugestões disponíveis no momento.',
          style: TextStyle(color: AppCores.fontes, fontSize: 14.0),
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ListView.separated(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: sugeridos.length,
          separatorBuilder: (context2, index2) =>
              const SizedBox(height: AppTamanhos.gapCandidaturas),
          itemBuilder: (context, index) {
            final badge = sugeridos[index];
            return BadgeProgressCard(
              titulo: badge['titulo'] as String? ?? '',
              categoria: badge['categoria'] as String? ?? 'Geral',
              pontos: badge['pontos'] as int? ?? 0,
              icon: badge['icon'] as IconData?,
              imagem: badge['imagem'] as String?,
              avatarColor: badge['avatarColor'] as Color? ?? const Color(0xFF3B82F6),
              progressoPercent: badge['progresso'] as int? ?? 0,
              especial: badge['especial'] as bool? ?? false,
              justificacao: badge['justificacao'] as String?,
              badgeDataOverride: badge,
            );
          },
        ),
      ],
    );
  }
}
