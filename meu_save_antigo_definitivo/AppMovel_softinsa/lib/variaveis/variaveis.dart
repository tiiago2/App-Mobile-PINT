import 'package:flutter/material.dart';

class AppCores {
  static const Color azulFundo = Color(0xFF39639C);
  static const Color azulClaro = Color(0xFFA7EFFF);
  static const Color fundo2 = Color(0xFFF8FAFD);
  static const Color branco = Color(0xFFFFFFFF);
  static const Color fontes = Color(0xFF374957);
  static const Color outline = Color(0xFFCAD5E2);
  static const Color fundoLoginSecundario = Color(0xFFF8FAFD);
  static const Color fundoLoginDestaqueRadial = Color(0x59A7EFFF);
  static const Color erroLogin = Color(0xFFD42A2A);
  static const Color sucessoLogin = Color(0xFF009966);
  static const Color focoLogin = Color(0x1F39639C);
  static const Color erroLoginFundo = Color(0x14D42A2A);
  static const Color erroLoginBorda = Color(0x40D42A2A);
  static const Color sucessoLoginFundo = Color(0x1428A745);
  static const Color sucessoLoginBorda = Color(0x4028A745);
  static const Color spinnerLogin = Color(0x73FFFFFF);
}

class AppTamanhos {
  static const double iconeNavegacao = 24.0;
  static const double titulo = 20.0;
  static const double espacamentoIcones = 8.0;
  static const double iconeSearchbarFilter = 20.0;
  static const double gapCandidaturas = 13.0;
  static const double gapPerfil = 30.0;
  static const double gapBadgesPessoais = 20.0;
  static const double colocacao_titulo = 30.0;
  static const double margemEcra = 16.0;
  static const double loginLarguraMaximaCard = 440.0;
  static const double loginAlturaInput = 44.0;
  static const double loginTamanhoSpinner = 16.0;
  static const double loginEspessuraSpinner = 2.0;
  static const double loginLarguraLogo = 88.0;
  static const double loginAlturaTopBar = 64.0;
  static const double logoutDialogLarguraMaxima = 420.0;
  static const double logoutDialogAlturaBotao = 44.0;
  static const double logoutDialogLarguraEmpilharAcoes = 300.0;
}

class AppBorders {
  static const double padrao = 14.0;
  static const double padrao_pequeno = 12.0;
  static const double pilulas = 18.0;
  static const double loginCampo = 8.0;
  static const double espessuraPrincipal = 1.6;
  static const double loginCircular = 999.0;
}

abstract final class AppEspacamentos {
  static const double loginTopBarPaddingHorizontal = 8.0;
  static const double loginTopBarPaddingVertical = 4.0;
  static const double loginLogoMargemEsquerda = 8.0;

  static const double loginPaddingPagina = 32.0;
  static const double loginPaddingCard = 32.0;
  static const double loginGapCard = 22.0;
  static const double loginGapCabecalho = 8.0;

  static const double loginGapFormulario = 14.0;
  static const double loginGapLabelInput = 6.0;
  static const double loginGapAcoes = 12.0;

  static const double loginPaddingHorizontalInput = 14.0;
  static const double loginPaddingDireitaPassword = 82.0;
  static const double loginPasswordToggleDireita = 12.0;

  static const double loginPaddingFeedbackVertical = 12.0;
  static const double loginPaddingFeedbackHorizontal = 14.0;
  static const double loginGapFeedback = 8.0;

  static const double loginGapBotaoConteudo = 8.0;

  static const double logoutDialogMargemHorizontal = 24.0;
  static const double logoutDialogPadding = 24.0;
  static const double logoutDialogGapTituloMensagem = 12.0;
  static const double logoutDialogGapAcoes = 24.0;
  static const double logoutDialogGapEntreBotoes = 12.0;
  static const double logoutDialogPaddingBotaoHorizontal = 16.0;
}

abstract final class AppSombras {
  static const BoxShadow loginCard = BoxShadow(
    color: Color(0x1F374957),
    offset: Offset(0, 12),
    blurRadius: 35,
  );

  static const BoxShadow loginTopBar = BoxShadow(
    color: Color(0x40000000),
    offset: Offset(0, 4),
    blurRadius: 4,
  );

  static const BoxShadow loginCampoFoco = BoxShadow(
    color: AppCores.focoLogin,
    offset: Offset.zero,
    blurRadius: 0,
    spreadRadius: 3,
  );
}
