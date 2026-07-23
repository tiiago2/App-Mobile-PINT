import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../controllers/auth_controller.dart';
import '../idiomas/app_localizations.dart';
import '../services/api_service.dart';
import '../variaveis/tipografia.dart';
import '../variaveis/variaveis.dart';
import '../widgets/auth_top_bar.dart';

class PrimeiroAcessoScreen extends StatefulWidget {
  final String? emailInicial;

  const PrimeiroAcessoScreen({super.key, this.emailInicial});

  @override
  State<PrimeiroAcessoScreen> createState() => _PrimeiroAcessoScreenState();
}

class _PrimeiroAcessoScreenState extends State<PrimeiroAcessoScreen> {
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
  bool _aceitouPoliticas = false;
  bool _isLoading = false;
  bool _submetidoComSucesso = false;
  String? _erroGeral;
  String? _mensagemSucesso;
  String? _emailErro;
  String? _passwordErro;
  String? _confirmarPasswordErro;
  String? _politicasErro;

  bool get _emailReadOnly =>
      widget.emailInicial != null && widget.emailInicial!.trim().isNotEmpty;

  @override
  void initState() {
    super.initState();
    if (_emailReadOnly) {
      _emailController.text = widget.emailInicial!.trim();
    }
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
    String? politicasErro;

    if (email.isEmpty) {
      emailErro = l10n.authCampoObrigatorio;
    } else if (!_emailValido(email)) {
      emailErro = l10n.authEmailInvalido;
    }

    if (password.isEmpty) {
      passwordErro = l10n.authCampoObrigatorio;
    }

    if (confirmarPassword.isEmpty) {
      confirmarPasswordErro = l10n.authCampoObrigatorio;
    } else if (password.isNotEmpty && password != confirmarPassword) {
      confirmarPasswordErro = l10n.authPasswordsDiferentes;
    }

    if (!_aceitouPoliticas) {
      politicasErro = l10n.authPoliticasObrigatorias;
    }

    setState(() {
      _erroGeral = null;
      _mensagemSucesso = null;
      _emailErro = emailErro;
      _passwordErro = passwordErro;
      _confirmarPasswordErro = confirmarPasswordErro;
      _politicasErro = politicasErro;
    });

    return emailErro == null &&
        passwordErro == null &&
        confirmarPasswordErro == null &&
        politicasErro == null;
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

  Future<void> _submeterPrimeiroAcesso() async {
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
      final mensagem = await _apiService.primeiroAcesso(
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
        _aceitouPoliticas = false;
        _submetidoComSucesso = true;
        _mensagemSucesso =
            mensagem == 'success' ? l10n.authPrimeiroAcessoSucesso : mensagem;
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
                                        l10n.authPrimeiroAcessoTitulo,
                                        style: AppTipografia.loginTitulo,
                                      ),
                                      const SizedBox(
                                        height:
                                            AppEspacamentos.loginGapCabecalho,
                                      ),
                                      Text(
                                        l10n.authPrimeiroAcessoSubtitulo,
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
                                      _PrimeiroAcessoTextField(
                                        controller: _emailController,
                                        focusNode: _emailFocusNode,
                                        label: l10n.authLoginEmail,
                                        errorText: _emailErro,
                                        readOnly: _emailReadOnly,
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
                                      _PrimeiroAcessoTextField(
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
                                      _PrimeiroAcessoTextField(
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
                                        height:
                                            AppEspacamentos.loginGapFormulario,
                                      ),
                                      _PoliticasCheckbox(
                                        value: _aceitouPoliticas,
                                        text: l10n.authAceitarPoliticas,
                                        errorText: _politicasErro,
                                        onChanged: _submetidoComSucesso
                                            ? null
                                            : (value) {
                                                setState(() {
                                                  _aceitouPoliticas =
                                                      value ?? false;
                                                  _politicasErro = null;
                                                });
                                              },
                                      ),
                                      const SizedBox(
                                        height: AppEspacamentos.loginGapAcoes,
                                      ),
                                      _AuthPrimaryButton(
                                        text: l10n.authPrimeiroAcessoBotao,
                                        isLoading: _isLoading,
                                        isDisabled: _submetidoComSucesso,
                                        onPressed: _submeterPrimeiroAcesso,
                                      ),
                                      if (_submetidoComSucesso) ...[
                                        const SizedBox(
                                          height: AppEspacamentos.loginGapAcoes,
                                        ),
                                        TextButton(
                                          onPressed: () {
                                            _removerFoco();
                                            AuthController.instance
                                                .clearFirstAccessRequirement();
                                            context.go('/login');
                                          },
                                          style: TextButton.styleFrom(
                                            foregroundColor:
                                                AppCores.azulFundo,
                                          ),
                                          child: Text(
                                            l10n.authVoltarLogin,
                                            style: AppTipografia.loginLink,
                                          ),
                                        ),
                                      ],
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

class _PrimeiroAcessoTextField extends StatelessWidget {
  final TextEditingController controller;
  final FocusNode focusNode;
  final String label;
  final String? errorText;
  final TextInputType? keyboardType;
  final Iterable<String>? autofillHints;
  final bool obscureText;
  final bool readOnly;
  final Widget? trailing;

  const _PrimeiroAcessoTextField({
    required this.controller,
    required this.focusNode,
    required this.label,
    this.errorText,
    this.keyboardType,
    this.autofillHints,
    this.obscureText = false,
    this.readOnly = false,
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
                readOnly: readOnly,
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

class _PoliticasCheckbox extends StatelessWidget {
  final bool value;
  final String text;
  final String? errorText;
  final ValueChanged<bool?>? onChanged;

  const _PoliticasCheckbox({
    required this.value,
    required this.text,
    required this.errorText,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final hasError = errorText != null;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
              width: AppTamanhos.loginAlturaInput,
              height: AppTamanhos.loginAlturaInput,
              child: Checkbox(
                value: value,
                onChanged: onChanged,
                activeColor: AppCores.azulFundo,
                checkColor: AppCores.branco,
                side: BorderSide(
                  color: hasError ? AppCores.erroLogin : AppCores.outline,
                  width: AppBorders.espessuraPrincipal,
                ),
              ),
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.only(
                  top: AppEspacamentos.loginGapLabelInput,
                ),
                child: Text(text, style: AppTipografia.loginLabel),
              ),
            ),
          ],
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
  final bool isDisabled;
  final VoidCallback onPressed;

  const _AuthPrimaryButton({
    required this.text,
    required this.isLoading,
    this.isDisabled = false,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: TextButton(
        onPressed: isLoading || isDisabled ? null : onPressed,
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
