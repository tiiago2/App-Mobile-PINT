import 'dart:async';

import 'package:flutter/material.dart';
import 'routes/routes_app.dart';
import 'controllers/auth_controller.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'idiomas/app_localizations.dart';
import 'variaveis/variaveis.dart';

final ValueNotifier<Locale?> appLocaleNotifier = ValueNotifier(null);

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  unawaited(AuthController.instance.initialize());
  runApp(const MinhaApp());
}

class MinhaApp extends StatelessWidget {
  const MinhaApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<Locale?>(
      valueListenable: appLocaleNotifier,
      builder: (context, localeOverride, _) {
        return MaterialApp.router(
          locale: localeOverride,
          title: 'App Softinsa',
          debugShowCheckedModeBanner: false, // Remove a fita "Debug" do canto superior direito
          routerConfig: AppRoutes.router,    // Entrega o volante ao GoRouter
          localizationsDelegates: const [
            AppLocalizations.delegate, // O ficheiro que o Flutter gera automaticamente
            GlobalMaterialLocalizations.delegate, // Traduz componentes base (como calendários)
            GlobalWidgetsLocalizations.delegate,  // Traduz a direção do texto (Esquerda/Direita)
            GlobalCupertinoLocalizations.delegate, // Traduz componentes estilo Apple
          ],
      supportedLocales: const [
        Locale('en'), // Inglês (Primeiro para ser o fallback padrão do sistema nalguns casos)
        Locale('pt'), // Português
        Locale('es'), // Espanhol
      ],
      localeResolutionCallback: (locale, supportedLocales) {
        // Se a língua do telemóvel estiver vazia por algum motivo
        if (locale == null) return const Locale('en');
        
        // Verifica se a língua do telemóvel é suportada pela nossa app
        for (var supportedLocale in supportedLocales) {
          if (supportedLocale.languageCode == locale.languageCode) {
            return supportedLocale;
          }
        }
        
        // Caso a língua do telemóvel não seja suportada (ex: Francês), usa Inglês
        return const Locale('en');
      },
      theme: ThemeData(
        useMaterial3: true,
        scaffoldBackgroundColor: AppCores.branco,
        textTheme: GoogleFonts.interTextTheme(
          Theme.of(context).textTheme,
        ),
      ),
    );
  },
);
  }
}
