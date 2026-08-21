import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../idiomas/app_localizations.dart';
import '../services/api_service.dart';
import '../variaveis/tipografia.dart';
import '../variaveis/variaveis.dart';
import '../widgets/auth_top_bar.dart';

class EsqueciPasswordScreen extends StatefulWidget {
  const EsqueciPasswordScreen({super.key});

  @override
  State<EsqueciPasswordScreen> createState() => _EsqueciPasswordScreenState();
}

class _EsqueciPasswordScreenState extends State<EsqueciPasswordScreen> {
  final ApiService _apiService = ApiService();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _confirmarPasswordController =
      TextEditingController();
  final FocusNode _emailFocusNode = FocusNode();
  final FocusNode _passwordFocusNode = FocusNode();
  final FocusNode _confirmarPasswordFocusNode = FocusNode();
  bool _mostrarPassword = false;
  bool _mostrarConfirmarPassword = false;
  bool _isLoading = false;
  String? _erroGeral;
  String? _mensagemSucesso;
  String? _emailErro;
  String? _passwordErro;
  String? _confirmarPasswordErro;

  @override
  void initState() {
    super.initState();
    _emailFocusNode.addListener(_atualizarFoco);
    _passwordFocusNode.addListener(_atualizarFoco);
    _confirmarPasswordFocusNode.addListener(_atualizarFoco);
  }

  @override
  void dispose() {
    _emailFocusNode
      ..removeListener(_atualizarFoco)
      ..dispose();
    _passwordFocusNode
      ..removeListener(_atualizarFoco)
      ..dispose();
    _confirmarPasswordFocusNode
      ..removeListener(_atualizarFoco)
      ..dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmarPasswordController.dispose();
    _apiService.dispose();
    super.dispose();
  }

  void _atualizarFoco() {
    setState(() {});
  }

  void _removerFoco() {
    FocusManager.instance.primaryFocus?.unfocus();
  }

  bool _emailValido(String email) {
    return RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]+$').hasMatch(email);
  }

  bool _validarCampos(AppLocalizations l10n) {
    final email = _emailController.text.trim();
    final password = _passwordController.text;
    final confirmarPassword = _confirmarPasswordController.text;
    String? emailErro;
    String? passwordErro;
    String? confirmarPasswordErro;

    if (email.isEmpty) {
      emailErro = l10n.authCampoObrigatorio;
    } else if (!_emailValido(email)) {
      emailErro = l10n.authEmailInvalido;
    }

    if (password.isEmpty) {
      passwordErro = l10n.authCampoObrigatorio;
    } else if (password.length < 6) {
      passwordErro = 'A password deve ter pelo menos 6 caracteres.';
    }

    if (confirmarPassword.isEmpty) {
      confirmarPasswordErro = l10n.authCampoObrigatorio;
    } else if (password.isNotEmpty && password != confirmarPassword) {
      confirmarPasswordErro = l10n.authPasswordsDiferentes;
    }

    setState(() {
      _erroGeral = null;
      _mensagemSucesso = null;
      _emailErro = emailErro;
      _passwordErro = passwordErro;
      _confirmarPasswordErro = confirmarPasswordErro;
    });

    return emailErro == null &&
        passwordErro == null &&
        confirmarPasswordErro == null;
  }

  String _mapearErro(AppLocalizations l10n, ApiException erro) {
    if (erro.message == 'connection' || erro.message == 'timeout') {
      return l10n.authErroLigacao;
    }

    if (erro.message == 'invalid_json' || erro.message == 'error') {
      return l10n.authErroGenerico;
    }

    return erro.message;
  }

  Future<void> _submeterRecuperacao() async {
    if (_isLoading) {
      return;
    }

    final l10n = AppLocalizations.of(context)!;
    _removerFoco();

    if (!_validarCampos(l10n)) {
      return;
    }

    setState(() {
      _isLoading = true;
      _erroGeral = null;
      _mensagemSucesso = null;
    });

    try {
      final mensagem = await _apiService.esqueciPassword(
        email: _emailController.text.trim(),
        password: _passwordController.text,
        confirmPassword: _confirmarPasswordController.text,
      );

      if (!mounted) {
        return;
      }

      _passwordController.clear();
      _confirmarPasswordController.clear();
      setState(() {
        _mensagemSucesso =
            mensagem == 'success' ? l10n.authRecuperarSucesso : mensagem;
      });
    } on ApiException catch (erro) {
      if (!mounted) {
        return;
      }

      setState(() {
        _erroGeral = _mapearErro(l10n, erro);
      });
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Stack(
        children: [
          const Positioned.fill(
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [AppCores.branco, AppCores.fundoLoginSecundario],
                ),
              ),
            ),
          ),
          const Positioned.fill(
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: RadialGradient(
                  center: Alignment(0.30, -0.15),
                  radius: 1.0,
                  colors: [
                    AppCores.fundoLoginDestaqueRadial,
                    Colors.transparent,
                    Colors.transparent,
                  ],
                  stops: [0.0, 0.32, 1.0],
                ),
              ),
            ),
          ),
          Column(
            children: [
              const AuthTopBar(),
              Expanded(
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    return SingleChildScrollView(
                      child: ConstrainedBox(
                        constraints: BoxConstraints(
                          minHeight: constraints.maxHeight,
                        ),
                        child: Center(
                          child: Padding(
                            padding: const EdgeInsets.all(
                              AppEspacamentos.loginPaddingPagina,
                            ),
                            child: ConstrainedBox(
                              constraints: const BoxConstraints(
                                maxWidth: AppTamanhos.loginLarguraMaximaCard,
                              ),
                              child: Container(
                                width: double.infinity,
                                padding: const EdgeInsets.all(
                                  AppEspacamentos.loginPaddingCard,
                                ),
                                decoration: BoxDecoration(
                                  color: AppCores.branco,
                                  borderRadius: BorderRadius.circular(
                                    AppBorders.padrao,
                                  ),
                                  border: Border.all(
                                    color: AppCores.outline,
                                    width: AppBorders.espessuraPrincipal,
                                  ),
                                  boxShadow: const [AppSombras.loginCard],
                                ),
                                child: AutofillGroup(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.stretch,
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Text(
                                        l10n.authRecuperarTitulo,
                                        style: AppTipografia.loginTitulo,
                                      ),
                                      const SizedBox(
                                        height:
                                            AppEspacamentos.loginGapCabecalho,
                                      ),
                                      Text(
                                        l10n.authRecuperarSubtitulo,
                                        style: AppTipografia.loginSubtitulo,
                                      ),
                                      const SizedBox(
                                        height: AppEspacamentos.loginGapCard,
                                      ),
                                      if (_erroGeral != null) ...[
                                        _AuthFeedback(
                                          text: _erroGeral!,
                                          isSuccess: false,
                                        ),
                                        const SizedBox(
                                          height: AppEspacamentos
                                              .loginGapFormulario,
                                        ),
                                      ],
                                      if (_mensagemSucesso != null) ...[
                                        _AuthFeedback(
                                          text: _mensagemSucesso!,
                                          isSuccess: true,
                                        ),
                                        const SizedBox(
                                          height: AppEspacamentos
                                              .loginGapFormulario,
                                        ),
                                      ],
                                      _EsqueciPasswordTextField(
                                        controller: _emailController,
                                        focusNode: _emailFocusNode,
                                        label: l10n.authLoginEmail,
                                        errorText: _emailErro,
                                        keyboardType:
                                            TextInputType.emailAddress,
                                        autofillHints: const [
                                          AutofillHints.email,
                                        ],
                                      ),
                                      const SizedBox(
                                        height:
                                            AppEspacamentos.loginGapFormulario,
                                      ),
                                      _EsqueciPasswordTextField(
                                        controller: _passwordController,
                                        focusNode: _passwordFocusNode,
                                        label: l10n.authNovaPassword,
                                        errorText: _passwordErro,
                                        obscureText: !_mostrarPassword,
                                        autofillHints: const [
                                          AutofillHints.newPassword,
                                        ],
                                        trailing: _PasswordToggle(
                                          mostrarPassword: _mostrarPassword,
                                          onPressed: () {
                                            setState(() {
                                              _mostrarPassword =
                                                  !_mostrarPassword;
                                            });
                                          },
                                        ),
                                      ),
                                      const SizedBox(
                                        height:
                                            AppEspacamentos.loginGapFormulario,
                                      ),
                                      _EsqueciPasswordTextField(
                                        controller:
                                            _confirmarPasswordController,
                                        focusNode:
                                            _confirmarPasswordFocusNode,
                                        label: l10n.authConfirmarPassword,
                                        errorText: _confirmarPasswordErro,
                                        obscureText:
                                            !_mostrarConfirmarPassword,
                                        autofillHints: const [
                                          AutofillHints.newPassword,
                                        ],
                                        trailing: _PasswordToggle(
                                          mostrarPassword:
                                              _mostrarConfirmarPassword,
                                          onPressed: () {
                                            setState(() {
                                              _mostrarConfirmarPassword =
                                                  !_mostrarConfirmarPassword;
                                            });
                                          },
                                        ),
                                      ),
                                      const SizedBox(
                                        height: AppEspacamentos.loginGapAcoes,
                                      ),
                                      _AuthPrimaryButton(
                                        text: l10n.authRecuperarBotao,
                                        isLoading: _isLoading,
                                        onPressed: _submeterRecuperacao,
                                      ),
                                      const SizedBox(
                                        height: AppEspacamentos.loginGapAcoes,
                                      ),
                                      TextButton(
                                        onPressed: () {
                                          _removerFoco();
                                          context.go('/login');
                                        },
                                        style: TextButton.styleFrom(
                                          foregroundColor: AppCores.azulFundo,
                                        ),
                                        child: Text(
                                          l10n.authVoltarLogin,
                                          style: AppTipografia.loginLink,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _EsqueciPasswordTextField extends StatelessWidget {
  final TextEditingController controller;
  final FocusNode focusNode;
  final String label;
  final String? errorText;
  final TextInputType? keyboardType;
  final Iterable<String>? autofillHints;
  final bool obscureText;
  final Widget? trailing;

  const _EsqueciPasswordTextField({
    required this.controller,
    required this.focusNode,
    required this.label,
    this.errorText,
    this.keyboardType,
    this.autofillHints,
    this.obscureText = false,
    this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    final isFocused = focusNode.hasFocus;
    final hasError = errorText != null;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: AppTipografia.loginLabel),
        const SizedBox(height: AppEspacamentos.loginGapLabelInput),
        Container(
          height: AppTamanhos.loginAlturaInput,
          decoration: BoxDecoration(
            color: AppCores.branco,
            borderRadius: BorderRadius.circular(AppBorders.loginCampo),
            border: Border.all(
              color: hasError
                  ? AppCores.erroLogin
                  : isFocused
                      ? AppCores.azulFundo
                      : AppCores.outline,
              width: AppBorders.espessuraPrincipal,
            ),
            boxShadow: isFocused && !hasError
                ? const [AppSombras.loginCampoFoco]
                : null,
          ),
          child: Stack(
            alignment: Alignment.centerRight,
            children: [
              TextField(
                controller: controller,
                focusNode: focusNode,
                keyboardType: keyboardType,
                autofillHints: autofillHints,
                obscureText: obscureText,
                style: AppTipografia.loginInput,
                decoration: InputDecoration(
                  border: InputBorder.none,
                  isDense: true,
                  contentPadding: EdgeInsets.only(
                    left: AppEspacamentos.loginPaddingHorizontalInput,
                    right: trailing == null
                        ? AppEspacamentos.loginPaddingHorizontalInput
                        : AppEspacamentos.loginPaddingDireitaPassword,
                  ),
                ),
              ),
              if (trailing != null)
                Positioned(
                  right: AppEspacamentos.loginPasswordToggleDireita,
                  child: trailing!,
                ),
            ],
          ),
        ),
        if (hasError) ...[
          const SizedBox(height: AppEspacamentos.loginGapLabelInput),
          Text(
            errorText!,
            style: AppTipografia.loginFeedback.copyWith(
              color: AppCores.erroLogin,
            ),
          ),
        ],
      ],
    );
  }
}

class _PasswordToggle extends StatelessWidget {
  final bool mostrarPassword;
  final VoidCallback onPressed;

  const _PasswordToggle({
    required this.mostrarPassword,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return TextButton(
      style: TextButton.styleFrom(
        foregroundColor: AppCores.azulFundo,
        padding: EdgeInsets.zero,
        minimumSize: Size.zero,
        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
      ),
      onPressed: onPressed,
      child: Text(
        mostrarPassword
            ? l10n.authLoginPasswordOcultar
            : l10n.authLoginPasswordMostrar,
        style: AppTipografia.loginLink,
      ),
    );
  }
}

class _AuthFeedback extends StatelessWidget {
  final String text;
  final bool isSuccess;

  const _AuthFeedback({
    required this.text,
    required this.isSuccess,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        vertical: AppEspacamentos.loginPaddingFeedbackVertical,
        horizontal: AppEspacamentos.loginPaddingFeedbackHorizontal,
      ),
      decoration: BoxDecoration(
        color: isSuccess ? AppCores.sucessoLoginFundo : AppCores.erroLoginFundo,
        borderRadius: BorderRadius.circular(AppBorders.loginCampo),
        border: Border.all(
          color:
              isSuccess ? AppCores.sucessoLoginBorda : AppCores.erroLoginBorda,
          width: AppBorders.espessuraPrincipal,
        ),
      ),
      child: Text(
        text,
        style: AppTipografia.loginFeedback.copyWith(
          color: isSuccess ? AppCores.sucessoLogin : AppCores.erroLogin,
        ),
      ),
    );
  }
}

class _AuthPrimaryButton extends StatelessWidget {
  final String text;
  final bool isLoading;
  final VoidCallback onPressed;

  const _AuthPrimaryButton({
    required this.text,
    required this.isLoading,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: TextButton(
        onPressed: isLoading ? null : onPressed,
        style: TextButton.styleFrom(
          minimumSize: const Size.fromHeight(AppTamanhos.loginAlturaInput),
          backgroundColor: AppCores.azulFundo,
          foregroundColor: AppCores.branco,
          disabledBackgroundColor: AppCores.azulFundo,
          disabledForegroundColor: AppCores.branco,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppBorders.loginCampo),
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            if (isLoading)
              const SizedBox(
                width: AppTamanhos.loginTamanhoSpinner,
                height: AppTamanhos.loginTamanhoSpinner,
                child: CircularProgressIndicator(
                  strokeWidth: AppTamanhos.loginEspessuraSpinner,
                  valueColor: AlwaysStoppedAnimation<Color>(AppCores.branco),
                  backgroundColor: AppCores.spinnerLogin,
                ),
              )
            else
              Text(text, style: AppTipografia.loginBotao),
          ],
        ),
      ),
    );
  }
}
