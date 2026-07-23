import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'variaveis.dart';

abstract final class AppTipografia {
  static final TextStyle loginTitulo = GoogleFonts.inter(
    fontSize: 32,
    fontWeight: FontWeight.w600,
    height: 1.2,
    color: AppCores.fontes,
  );

  static final TextStyle loginSubtitulo = GoogleFonts.inter(
    fontSize: 16,
    fontWeight: FontWeight.w400,
    height: 1.5,
    color: AppCores.fontes,
  );

  static final TextStyle loginLabel = GoogleFonts.inter(
    fontSize: 14,
    fontWeight: FontWeight.w600,
    color: AppCores.fontes,
  );

  static final TextStyle loginInput = GoogleFonts.inter(
    fontSize: 14,
    fontWeight: FontWeight.w400,
    color: AppCores.fontes,
  );

  static final TextStyle loginLink = GoogleFonts.inter(
    fontSize: 14,
    fontWeight: FontWeight.w600,
    color: AppCores.azulFundo,
  );

  static final TextStyle loginFeedback = GoogleFonts.inter(
    fontSize: 14,
    fontWeight: FontWeight.w400,
    height: 1.4,
    color: AppCores.fontes,
  );

  static final TextStyle loginBotao = GoogleFonts.inter(
    fontSize: 14,
    fontWeight: FontWeight.w700,
    color: AppCores.branco,
  );

  static final TextStyle logoutDialogTitulo = GoogleFonts.inter(
    fontSize: 22,
    fontWeight: FontWeight.w600,
    height: 1.2,
    color: AppCores.fontes,
  );

  static final TextStyle logoutDialogMensagem = GoogleFonts.inter(
    fontSize: 14,
    fontWeight: FontWeight.w400,
    height: 1.5,
    color: AppCores.fontes,
  );

  static final TextStyle logoutDialogBotaoCancelar = GoogleFonts.inter(
    fontSize: 14,
    fontWeight: FontWeight.w700,
    color: AppCores.azulFundo,
  );

  static final TextStyle logoutDialogBotaoConfirmar = GoogleFonts.inter(
    fontSize: 14,
    fontWeight: FontWeight.w700,
    color: AppCores.branco,
  );
}
