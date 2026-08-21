import 'package:flutter/material.dart';
import '../../variaveis/variaveis.dart';
import '../badge_progress_card.dart';
import '../../controllers/badges_controller.dart';

class AbaSugeridos extends StatelessWidget {
  const AbaSugeridos({super.key});

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: BadgesController.instance,
      builder: (context, _) {
        final badges = BadgesController.instance.badges;
        if (badges.isEmpty) {
          return const Padding(
            padding: EdgeInsets.all(24.0),
            child: Center(
              child: Text(
                'Nenhum badge sugerido de momento.',
                style: TextStyle(color: AppCores.fontes),
              ),
            ),
          );
        }

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: badges.length > 8 ? 8 : badges.length,
              separatorBuilder: (_, __) =>
                  const SizedBox(height: AppTamanhos.gapCandidaturas),
              itemBuilder: (context, index) {
                final badge = badges[index];
                final String titulo = (badge['titulo'] ?? badge['nome_badge'] ?? '').toString();
                final String categoria = (badge['areaNome'] ?? badge['area'] ?? 'Geral').toString();
                final int pontos = int.tryParse((badge['pontos'] ?? badge['pontos_badge'] ?? '0').toString()) ?? 0;
                final String? imagem = badge['imagem'] as String?;
                final bool especial = badge['especial'] == true || badge['especial'] == 1 || badge['especial'] == '1';

                return BadgeProgressCard(
                  titulo: titulo,
                  categoria: categoria,
                  pontos: pontos,
                  imagem: imagem,
                  avatarColor: const Color(0xFF39639C),
                  progressoPercent: (badge['progresso'] as int?) ?? 50,
                  especial: especial,
                );
              },
            ),
          ],
        );
      },
    );
  }
}
