import 'package:flutter/material.dart';
import 'package:uicons/uicons.dart';
import '../../idiomas/app_localizations.dart';

class DivisaoEspeciais extends StatelessWidget {
  const DivisaoEspeciais({super.key});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        // Ícone Dourado
        Icon(
          UIcons.boldRounded.badge, 
          color: const Color(0xFFF8AA0B),
          size: 20.0,
        ),
        const SizedBox(width: 8.0),
        
        // Texto
        Text(
          AppLocalizations.of(context)?.badgesEspeciais ?? 'BADGES ESPECIAIS',
          style: const TextStyle(
            color: Color(0xFFF8AA0B),
            fontSize: 14.0,
            fontWeight: FontWeight.w500, // Medium
          ),
        ),
        const SizedBox(width: 12.0),
        
        // Linha com Degradé (preenche o resto do ecrã à direita)
        Expanded(
          child: Container(
            height: 2.0, 
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [Color(0xFFF8AA0B), Colors.white],
                begin: Alignment.centerLeft,
                end: Alignment.centerRight,
              ),
            ),
          ),
        ),
      ],
    );
  }
}
