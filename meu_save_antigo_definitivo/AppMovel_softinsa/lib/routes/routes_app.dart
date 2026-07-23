import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../navigation/navegacao_app.dart';
import '../controllers/auth_controller.dart';

import 'package:app_movel_softinsa/pages/candidaturas.dart';
import 'package:app_movel_softinsa/pages/perfil.dart';
import 'package:app_movel_softinsa/pages/editarperfil.dart';
import 'package:app_movel_softinsa/pages/badgespessoais.dart';
import 'package:app_movel_softinsa/pages/estatisticas.dart';
import 'package:app_movel_softinsa/pages/galeria.dart';
// import 'package:app_movel_softinsa/pages/login.dart';
// import 'package:app_movel_softinsa/pages/esqueci_password.dart';
// import 'package:app_movel_softinsa/pages/primeiro_acesso.dart';
import 'package:app_movel_softinsa/pages/session_loading.dart';
import 'package:app_movel_softinsa/pages/objetivos.dart';
import 'package:app_movel_softinsa/pages/home.dart';

class AppRoutes {
  static final _rootNavigatorKey = GlobalKey<NavigatorState>();
  static final _shellNavigatorKey = GlobalKey<NavigatorState>();
  static final AuthController _authController = AuthController.instance;

  static final router = GoRouter(
    navigatorKey: _rootNavigatorKey,
    refreshListenable: _authController,
    initialLocation: '/session-loading',
    redirect: (context, state) {
      final location = state.matchedLocation;
      final status = _authController.status;
      final isLoadingRoute = location == '/session-loading';
      // final isLoginRoute = location == '/login';
      // final isForgotPasswordRoute = location == '/esqueci-password';
      // final isFirstAccessRoute = location == '/primeiro-acesso';
      // final isAuthRoute =
      //     isLoginRoute || isForgotPasswordRoute || isFirstAccessRoute;

      switch (status) {
        case AuthStatus.checking:
          return isLoadingRoute ? null : '/session-loading';
        // case AuthStatus.unauthenticated:
        //   if (isLoginRoute || isForgotPasswordRoute) {
        //     return null;
        //   }
        //   return isLoadingRoute ? '/login' : '/login';
        // case AuthStatus.firstAccessRequired:
        //   if (isFirstAccessRoute || isLoginRoute || isForgotPasswordRoute) {
        //     return null;
        //   }
        //   return '/primeiro-acesso';
        case AuthStatus.unauthenticated:
        case AuthStatus.firstAccessRequired:
        case AuthStatus.authenticatedOnline:
        case AuthStatus.authenticatedOffline:
          if (isLoadingRoute) {
            return '/home';
          }
          return null;
      }
    },
    routes: [
      GoRoute(
        path: '/session-loading',
        builder: (context, state) => const SessionLoadingScreen(),
      ),
      // GoRoute(
      //   path: '/login',
      //   builder: (context, state) => const LoginScreen(),
      // ),
      // GoRoute(
      //   path: '/esqueci-password',
      //   builder: (context, state) => const EsqueciPasswordScreen(),
      // ),
      // GoRoute(
      //   path: '/primeiro-acesso',
      //   builder: (context, state) {
      //     final emailInicial =
      //         state.extra as String? ?? _authController.firstAccessEmail;
      //     return PrimeiroAcessoScreen(
      //       emailInicial: emailInicial,
      //     );
      //   },
      // ),
      // A NOSSA "CASCA" (Barra de Navegação)
      ShellRoute(
        navigatorKey: _shellNavigatorKey,
        builder: (context, state, child) {
          return AppNavegacao(ecraAtual: child);
        },
        // AS ROTAS QUE VIVEM PROTEGIDAS DENTRO DA BARRA
        routes: [
          GoRoute(
            path: '/galeria',
            builder: (context, state) {
              final filtroInicial = state.uri.queryParameters['filtro'] ?? 'todos';
              return GaleriaScreen(filtroInicial: filtroInicial);
            },
          ),
          GoRoute(
            path: '/objetivos',
            builder: (context, state) => const ObjetivosScreen(),
          ),
          GoRoute(
            path: '/home',
            builder: (context, state) => const HomeScreen(),
          ),
          GoRoute(
            path: '/estatisticas',
            builder: (context, state) => const EstatisticasScreen(),
          ),
          GoRoute(
            path: '/perfil',
            builder: (context, state) => const PerfilScreen(),
          ),
          GoRoute(
            path: '/candidaturas',
            builder: (context, state) => const CandidaturasScreen(),
          ),
          GoRoute(
            path: '/editarperfil',
            builder: (context, state) => const EditarPerfilScreen(),
          ),
          GoRoute(
            path: '/badgespessoais',
            builder: (context, state) => const BadgesPessoaisScreen(),
          ),
        ],
      ),
    ],
  );
}
