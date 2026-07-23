import 'package:country_flags/country_flags.dart';
import 'package:flutter/material.dart';

import '../main.dart';
import '../variaveis/variaveis.dart';
import 'language_selector_dialog.dart';

class AuthTopBar extends StatelessWidget {
  const AuthTopBar({super.key});

  String _obterCodigoPais(BuildContext context) {
    final languageCode = Localizations.localeOf(context).languageCode;

    switch (languageCode) {
      case 'en':
        return 'GB';
      case 'es':
        return 'ES';
      case 'pt':
      default:
        return 'PT';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(
        horizontal: AppEspacamentos.loginTopBarPaddingHorizontal,
        vertical: AppEspacamentos.loginTopBarPaddingVertical,
      ),
      decoration: const BoxDecoration(
        color: AppCores.branco,
        boxShadow: [AppSombras.loginTopBar],
      ),
      child: SafeArea(
        bottom: false,
        child: SizedBox(
          height: AppTamanhos.loginAlturaTopBar,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Padding(
                padding: const EdgeInsets.only(
                  left: AppEspacamentos.loginLogoMargemEsquerda,
                ),
                child: Image.asset(
                  'assets/images/logotipo_softinsa.png',
                  width: AppTamanhos.loginLarguraLogo,
                  fit: BoxFit.contain,
                ),
              ),
              Builder(
                builder: (contextBotaoIdioma) {
                  return InkWell(
                    splashColor: Colors.transparent,
                    highlightColor: Colors.transparent,
                    borderRadius: BorderRadius.circular(
                      AppBorders.loginCircular,
                    ),
                    onTap: () async {
                      final caixaBotao =
                          contextBotaoIdioma.findRenderObject() as RenderBox;
                      final posicao = caixaBotao.localToGlobal(Offset.zero);
                      final tamanho = caixaBotao.size;
                      final larguraEcra = MediaQuery.of(
                        contextBotaoIdioma,
                      ).size.width;
                      final resultado = await showMenu<String>(
                        context: contextBotaoIdioma,
                        color: Colors.transparent,
                        elevation: 0,
                        position: RelativeRect.fromLTRB(
                          posicao.dx,
                          posicao.dy + tamanho.height - 4,
                          larguraEcra - posicao.dx - tamanho.width,
                          0,
                        ),
                        items: const [
                          PopupMenuItem<String>(
                            enabled: false,
                            padding: EdgeInsets.zero,
                            child: LanguageSelectorDialog(),
                          ),
                        ],
                      );

                      if (resultado != null) {
                        final localeCode = resultado == 'gb' ? 'en' : resultado;
                        appLocaleNotifier.value = Locale(localeCode);
                      }
                    },
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppTamanhos.espacamentoIcones,
                        vertical: AppEspacamentos.loginTopBarPaddingVertical,
                      ),
                      child: CountryFlag.fromCountryCode(
                        _obterCodigoPais(context),
                        theme: const ImageTheme(
                          width: AppTamanhos.iconeNavegacao,
                          height: AppTamanhos.iconeNavegacao,
                          shape: Circle(),
                        ),
                      ),
                    ),
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}
