import 'package:flutter/material.dart';
import '../../idiomas/app_localizations.dart';

class DivisaoOutrasAreas extends StatelessWidget {
  const DivisaoOutrasAreas({super.key});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        // Texto
        Text(
          AppLocalizations.of(context)?.outrasAreas ?? 'OUTRAS ÁREAS',
          style: const TextStyle(
            color: Color(0xFF6182B0), // Azul da fonte
            fontSize: 14.0,
            fontWeight: FontWeight.w500, // Medium
          ),
        ),
        const SizedBox(width: 12.0), // Espaçamento entre o texto e a linha
        
        // Linha sólida (preenche o resto do ecrã à direita)
        Expanded(
          child: Container(
            height: 1.0, 
            decoration: const BoxDecoration(
              color: Color(0xFFCAD5E2), // Cor do contorno/linha
            ),
          ),
        ),
      ],
    );
  }
}
