import 'package:flutter/material.dart';
import 'package:country_flags/country_flags.dart';
import '../variaveis/variaveis.dart';
import '../idiomas/app_localizations.dart';

class LanguageSelectorDialog extends StatelessWidget {
  const LanguageSelectorDialog({super.key});

  @override
  Widget build(BuildContext context) {
    // Retornamos diretamente o Material transparente para que 
    // a posição seja controlada inteiramente por quem chama este widget (o dropdown)
    return Material(
      type: MaterialType.transparency,
      child: Container(
        width: 200, // Um pouco mais largo, como pedido
          padding: const EdgeInsets.symmetric(vertical: 20.0, horizontal: 16.0),
          decoration: BoxDecoration(
            color: AppCores.branco,
            borderRadius: BorderRadius.circular(14.0),
            border: Border.all(color: AppCores.outline, width: 1.6),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  AppLocalizations.of(context)!.lingua,
                  style: const TextStyle(
                    fontWeight: FontWeight.w500, // Medium
                    fontSize: 20,
                    color: AppCores.fontes,
                  ),
                ),
              ),
              const SizedBox(height: 8),
              const Divider(
                color: AppCores.outline,
                thickness: 1.6,
                height: 1.6,
              ),
              const SizedBox(height: 12),
              _LanguageOption(
                language: AppLocalizations.of(context)!.portugues,
                countryCode: 'PT',
                onTap: () {
                  Navigator.pop(context, 'pt');
                },
              ),
              const SizedBox(height: 8),
              _LanguageOption(
                language: AppLocalizations.of(context)!.espanhol,
                countryCode: 'ES',
                onTap: () {
                  Navigator.pop(context, 'es');
                },
              ),
              const SizedBox(height: 8),
              _LanguageOption(
                language: AppLocalizations.of(context)!.ingles,
                countryCode: 'GB',
                onTap: () {
                  Navigator.pop(context, 'gb');
                },
              ),
            ],
          ),
        ),
      );
  }
}

class _LanguageOption extends StatelessWidget {
  final String language;
  final String countryCode;
  final VoidCallback onTap;

  const _LanguageOption({
    required this.language,
    required this.countryCode,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        height: 53.33,
        decoration: BoxDecoration(
          border: Border.all(color: AppCores.outline, width: 1.6),
          borderRadius: BorderRadius.circular(14.0),
        ),
        // Trocamos o Stack por uma Row para garantir que, por mais estreito 
        // que seja, o texto nunca sobrepõe a bandeira.
        child: Row(
          children: [
            const SizedBox(width: 12),
            CountryFlag.fromCountryCode(
              countryCode,
              theme: const ImageTheme(width: 34, height: 34, shape: Circle()),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                language,
                style: const TextStyle(
                  fontWeight: FontWeight.w400, // Regular
                  fontSize: 14,
                  color: AppCores.fontes,
                ),
                textAlign: TextAlign.left, // Mantém limpo à esquerda
              ),
            ),
            const SizedBox(width: 12),
          ],
        ),
      ),
    );
  }
}
