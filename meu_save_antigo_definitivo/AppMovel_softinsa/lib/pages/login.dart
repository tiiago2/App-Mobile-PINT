import 'dart:async';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../database/sync_manager.dart';
import '../services/fcm_service.dart';
import '../controllers/auth_controller.dart';
import '../idiomas/app_localizations.dart';
import '../services/api_service.dart';
import '../services/session_storage.dart';
import '../variaveis/tipografia.dart';
import '../variaveis/variaveis.dart';
import '../widgets/auth_top_bar.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final ApiService _apiService = ApiService();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final FocusNode _emailFocusNode = FocusNode();
  final FocusNode _passwordFocusNode = FocusNode();
  bool _mostrarPassword = false;
  bool _isLoading = false;
  String? _erroGeral;
  String? _emailErro;
  String? _passwordErro;

  @override
  void initState() {
    super.initState();
    _emailFocusNode.addListener(_atualizarFoco);
    _passwordFocusNode.addListener(_atualizarFoco);
  }

  @override
  void dispose() {
    _emailFocusNode
      ..removeListener(_atualizarFoco)
      ..dispose();
    _passwordFocusNode
      ..removeListener(_atualizarFoco)
      ..dispose();
    _emailController.dispose();
    _passwordController.dispose();
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
    String? emailErro;
    String? passwordErro;

    if (email.isEmpty) {
      emailErro = l10n.authCampoObrigatorio;
    } else if (!_emailValido(email)) {
      emailErro = l10n.authEmailInvalido;
    }

    if (password.isEmpty) {
      passwordErro = l10n.authCampoObrigatorio;
    }

    setState(() {
      _erroGeral = null;
      _emailErro = emailErro;
      _passwordErro = passwordErro;
    });

    return emailErro == null && passwordErro == null;
  }

  String _mapearErro(AppLocalizations l10n, ApiException erro) {
    if (erro.statusCode == 401) {
      return l10n.authLoginCredenciaisInvalidas;
    }

    if (erro.message == 'connection' || erro.message == 'timeout') {
      return l10n.authErroLigacao;
    }

    return l10n.authErroGenerico;
  }

  Future<void> _submeterLogin() async {
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
    });

    final email = _emailController.text.trim().toLowerCase();

    try {
      final response = await _apiService.login(
        email: email,
        password: _passwordController.text,
      );

      if (!mounted) {
        return;
      }

      if (response.requiresPasswordChange) {
        AuthController.instance.requireFirstAccess(email);
        context.go('/primeiro-acesso', extra: email);
        return;
      }

      final token = response.token;
      final refreshToken = response.refreshToken;

      if (token != null &&
          token.isNotEmpty &&
          refreshToken != null &&
          refreshToken.isNotEmpty) {
        await AuthController.instance.completeLogin(
          token: token,
          refreshToken: refreshToken,
          userJson: response.user,
        );

        // Inicializar o FCM e registar o token no servidor
        unawaited(FcmService.instance.inicializarFCM());
        FcmService.instance.inicializarListeners();

        // Disparar o Pull Sync inicial para carregar dados do utilizador
        final userIdRaw = response.user?['id'] ?? response.user?['id_utilizador'];
        final userId = userIdRaw != null ? int.tryParse(userIdRaw.toString()) : null;
        unawaited(SyncManager.instance.executePullSync(userId));

        if (!mounted) {
          return;
        }

        context.go('/home');
        return;
      }

      setState(() {
        _erroGeral = l10n.authErroGenerico;
      });
    } on SessionStorageException {
      if (!mounted) {
        return;
      }

      setState(() {
        _erroGeral = l10n.authErroGenerico;
      });
    } on ApiException catch (erro) {
      if (!mounted) {
        return;
      }

      setState(() {
        _erroGeral = _mapearErro(l10n, erro);
      });
    } catch (erro) {
      if (!mounted) {
        return;
      }

      setState(() {
        _erroGeral = l10n.authErroGenerico;
      });
      debugPrint('❌ Erro inesperado no login: $erro');
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
                                        l10n.authLoginTitulo,
                                        style: AppTipografia.loginTitulo,
                                      ),
                                      const SizedBox(
                                        height:
                                            AppEspacamentos.loginGapCabecalho,
                                      ),
                                      Text(
                                        l10n.authLoginSubtitulo,
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
                                      _LoginTextField(
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
                                      _LoginTextField(
                                        controller: _passwordController,
                                        focusNode: _passwordFocusNode,
                                        label: l10n.authLoginPassword,
                                        errorText: _passwordErro,
                                        obscureText: !_mostrarPassword,
                                        autofillHints: const [
                                          AutofillHints.password,
                                        ],
                                        trailing: TextButton(
                                          style: TextButton.styleFrom(
                                            foregroundColor:
                                                AppCores.azulFundo,
                                            padding: EdgeInsets.zero,
                                            minimumSize: Size.zero,
                                            tapTargetSize: MaterialTapTargetSize
                                                .shrinkWrap,
                                          ),
                                          onPressed: () {
                                            setState(() {
                                              _mostrarPassword =
                                                  !_mostrarPassword;
                                            });
                                          },
                                          child: Text(
                                            _mostrarPassword
                                                ? l10n
                                                    .authLoginPasswordOcultar
                                                : l10n
                                                    .authLoginPasswordMostrar,
                                            style: AppTipografia.loginLink,
                                          ),
                                        ),
                                      ),
                                      const SizedBox(
                                        height: AppEspacamentos.loginGapAcoes,
                                      ),
                                      _LoginPrimaryButton(
                                        text: l10n.authLoginEntrar,
                                        isLoading: _isLoading,
                                        onPressed: _submeterLogin,
                                      ),
                                      const SizedBox(
                                        height: AppEspacamentos.loginGapAcoes,
                                      ),
                                      TextButton(
                                        onPressed: () {
                                          _removerFoco();
                                          context.go('/esqueci-password');
                                        },
                                        style: TextButton.styleFrom(
                                          foregroundColor: AppCores.azulFundo,
                                        ),
                                        child: Text(
                                          l10n.authLoginEsqueciPassword,
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

class _LoginTextField extends StatelessWidget {
  final TextEditingController controller;
  final FocusNode focusNode;
  final String label;
  final String? errorText;
  final TextInputType? keyboardType;
  final Iterable<String>? autofillHints;
  final bool obscureText;
  final Widget? trailing;

  const _LoginTextField({
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

class _LoginPrimaryButton extends StatelessWidget {
  final String text;
  final bool isLoading;
  final VoidCallback onPressed;

  const _LoginPrimaryButton({
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
