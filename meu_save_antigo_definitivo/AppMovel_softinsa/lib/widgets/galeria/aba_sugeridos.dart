import 'package:flutter/material.dart';
import 'package:uicons/uicons.dart';
import '../../variaveis/variaveis.dart';
import '../badge_progress_card.dart';

class AbaSugeridos extends StatelessWidget {
  const AbaSugeridos({super.key});

  @override
  Widget build(BuildContext context) {
    // --- MOCK DATA (temporário enquanto não há API) --------------------------
    // Estrutura esperada por BadgeProgressCard:
    //   titulo, categoria, pontos, icon (IconData?), imagem (String? URL),
    //   avatarColor, progresso (0–100), especial (bool)
    final mockSugeridos = [
      {
        'titulo': 'Low Code Pro',
        'categoria': 'Low Code',
        'pontos': 200,
        'icon': UIcons.boldRounded.coffee,
        'imagem': null,
        'avatarColor': const Color(0xFF39639C),
        'progresso': 45,
        'especial': true,
      },
      {
        'titulo': 'Mobile Dev',
        'categoria': 'Low Code',
        'pontos': 150,
        'icon': UIcons.boldRounded.mobile_button,
        'imagem': null,
        'avatarColor': const Color(0xFF06B6D4),
        'progresso': 65,
        'especial': false,
      },
      {
        'titulo': 'Cloud Architect',
        'categoria': 'Cloud Computing',
        'pontos': 350,
        'icon': UIcons.boldRounded.database,
        'imagem': null,
        'avatarColor': const Color(0xFF8B5CF6),
        'progresso': 20,
        'especial': false,
      },
      {
        'titulo': 'UX/UI Design',
        'categoria': 'Design',
        'pontos': 250,
        'icon': UIcons.boldRounded.pencil,
        'imagem': null,
        'avatarColor': const Color(0xFFEC4899),
        'progresso': 80,
        'especial': false,
      },
      {
        'titulo': 'Scrum Master',
        'categoria': 'Agile',
        'pontos': 300,
        'icon': UIcons.boldRounded.bullseye,
        'imagem': null,
        'avatarColor': const Color(0xFFF97316),
        'progresso': 10,
        'especial': true,
      },
      {
        'titulo': 'DevOps Essentials',
        'categoria': 'DevOps',
        'pontos': 180,
        'icon': UIcons.boldRounded.settings,
        'imagem': null,
        'avatarColor': const Color(0xFF10B981),
        'progresso': 55,
        'especial': false,
      },
      {
        'titulo': 'Data Analyst',
        'categoria': 'Data & Analytics',
        'pontos': 220,
        'icon': UIcons.boldRounded.chart_histogram,
        'imagem': null,
        'avatarColor': const Color(0xFFF59E0B),
        'progresso': 35,
        'especial': false,
      },
      {
        'titulo': 'Cyber Security',
        'categoria': 'Segurança',
        'pontos': 400,
        'icon': UIcons.boldRounded.shield_check,
        'imagem': null,
        'avatarColor': const Color(0xFFEF4444),
        'progresso': 70,
        'especial': true,
      },
      {
        'titulo': 'Python Básico',
        'categoria': 'Backend',
        'pontos': 100,
        'icon': UIcons.boldRounded.code_branch,
        'imagem': null,
        'avatarColor': const Color(0xFF3B82F6),
        'progresso': 90,
        'especial': false,
      },
      {
        'titulo': 'Agile Fundamentals',
        'categoria': 'Management',
        'pontos': 130,
        'icon': UIcons.boldRounded.users,
        'imagem': null,
        'avatarColor': const Color(0xFF6366F1),
        'progresso': 15,
        'especial': false,
      },
    ];
    // -------------------------------------------------------------------------

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ListView.separated(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: mockSugeridos.length,
          separatorBuilder: (_, __) =>
              const SizedBox(height: AppTamanhos.gapCandidaturas),
          itemBuilder: (context, index) {
            final badge = mockSugeridos[index];
            return BadgeProgressCard(
              titulo: badge['titulo'] as String,
              categoria: badge['categoria'] as String,
              pontos: badge['pontos'] as int,
              icon: badge['icon'] as IconData?,
              imagem: badge['imagem'] as String?,
              avatarColor: badge['avatarColor'] as Color,
              progressoPercent: badge['progresso'] as int,
              especial: badge['especial'] as bool,
            );
          },
        ),
      ],
    );
  }
}
