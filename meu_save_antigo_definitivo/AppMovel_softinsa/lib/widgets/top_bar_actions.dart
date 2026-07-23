import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:uicons/uicons.dart';
import 'package:country_flags/country_flags.dart';

import '../variaveis/variaveis.dart';
import '../widgets/language_selector_dialog.dart';
import '../widgets/notificacoes_dialog.dart';
import '../main.dart';

class TopBarActions extends StatefulWidget {
  final bool showDocumentIcon;
  final bool showLogoutIcon;
  final VoidCallback? onLogoutPressed;

  const TopBarActions({
    super.key,
    this.showDocumentIcon = true,
    this.showLogoutIcon = false,
    this.onLogoutPressed,
  });

  @override
  State<TopBarActions> createState() => _TopBarActionsState();
}

class _TopBarActionsState extends State<TopBarActions> {
  String _obterCodigoPais(BuildContext context) {
    // Extract the active global locale from Flutter's Localizations system
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
    final double tamanhoIcone = AppTamanhos.iconeNavegacao;

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (widget.showLogoutIcon)
          InkWell(
            splashColor: Colors.transparent,
            highlightColor: Colors.transparent,
            borderRadius: BorderRadius.circular(50),
            onTap: widget.onLogoutPressed,
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: AppTamanhos.espacamentoIcones),
              child: Icon(
                UIcons.boldRounded.sign_out_alt,
                color: AppCores.fontes,
                size: tamanhoIcone,
              ),
            ),
          ),
        if (widget.showDocumentIcon)
          InkWell(
            splashColor: Colors.transparent,
            highlightColor: Colors.transparent,
            borderRadius: BorderRadius.circular(50),
            onTap: () {
              context.push('/candidaturas');
            },
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: AppTamanhos.espacamentoIcones),
              child: Icon(
                UIcons.boldRounded.document,
                color: AppCores.fontes,
                size: tamanhoIcone,
              ),
            ),
          ),
        
        // --- 1º BOTÃO: SELETOR DE IDIOMAS ---
        Builder(
          builder: (BuildContext contextBotaoIdioma) {
            return InkWell(
              splashColor: Colors.transparent,
              highlightColor: Colors.transparent,
              borderRadius: BorderRadius.circular(50),
              onTap: () async {
                final RenderBox caixaBotao = contextBotaoIdioma.findRenderObject() as RenderBox;
                final Offset posicaoGPS = caixaBotao.localToGlobal(Offset.zero);
                final Size tamanhoBotao = caixaBotao.size;
                final double larguraEcra = MediaQuery.of(contextBotaoIdioma).size.width;

                final double topoDinamico = posicaoGPS.dy + tamanhoBotao.height - 4;
                final double direitaDinamica = larguraEcra - posicaoGPS.dx - tamanhoBotao.width - 24;

                final String? resultado = await showMenu<String>(
                  context: contextBotaoIdioma,
                  color: Colors.transparent,
                  elevation: 0,
                  position: RelativeRect.fromLTRB(
                    posicaoGPS.dx + 24, 
                    topoDinamico, 
                    direitaDinamica, 
                    0,
                  ),
                  items: [
                    const PopupMenuItem<String>(
                      enabled: false,
                      padding: EdgeInsets.zero,
                      child: LanguageSelectorDialog(),
                    ),
                  ],
                );

                if (resultado != null) {
                  String localeCode = resultado == 'gb' ? 'en' : resultado;
                  appLocaleNotifier.value = Locale(localeCode);
                }
              },
              child: Padding(
                padding: EdgeInsets.symmetric(horizontal: AppTamanhos.espacamentoIcones),
                child: CountryFlag.fromCountryCode(
                  _obterCodigoPais(context),
                  theme: ImageTheme(
                    width: tamanhoIcone,
                    height: tamanhoIcone,
                    shape: const Circle(),
                  ),
                ),
              ),
            );
          },
        ),

        // --- 2º BOTÃO: NOTIFICAÇÕES ---
        Builder(
          builder: (BuildContext contextBotaoSino) {
            return InkWell(
              splashColor: Colors.transparent,
              highlightColor: Colors.transparent,
              borderRadius: BorderRadius.circular(50),
              onTap: () {
                final RenderBox caixaBotao = contextBotaoSino.findRenderObject() as RenderBox;
                final Offset posicaoGPS = caixaBotao.localToGlobal(Offset.zero);
                final Size tamanhoBotao = caixaBotao.size;
                final double larguraEcra = MediaQuery.of(contextBotaoSino).size.width;

                final double topoDinamico = posicaoGPS.dy + tamanhoBotao.height - 4;
                final double direitaDinamica = larguraEcra - posicaoGPS.dx - tamanhoBotao.width;

                showMenu(
                  context: contextBotaoSino,
                  color: Colors.transparent,
                  elevation: 0,
                  position: RelativeRect.fromLTRB(
                    posicaoGPS.dx, 
                    topoDinamico, 
                    direitaDinamica, 
                    0,
                  ),
                  items: [
                    const PopupMenuItem(
                      enabled: false,
                      padding: EdgeInsets.zero,
                      child: NotificacoesDialog(),
                    ),
                  ],
                );
              },
              child: Padding(
                padding: EdgeInsets.symmetric(horizontal: AppTamanhos.espacamentoIcones),
                child: Icon(UIcons.boldRounded.bell, color: AppCores.fontes, size: tamanhoIcone),
              ),
            );
          },
        ),
        SizedBox(width: AppTamanhos.espacamentoIcones),
      ],
    );
  }
}
