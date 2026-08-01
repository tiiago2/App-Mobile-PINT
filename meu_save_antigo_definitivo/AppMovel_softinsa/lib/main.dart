import 'dart:async';

import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'routes/routes_app.dart';
import 'controllers/auth_controller.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'idiomas/app_localizations.dart';
import 'variaveis/variaveis.dart';

// Importações do Motor de Sincronização
import 'database/database_helper.dart';
import 'database/local/secure_storage.dart';
import 'database/sync_manager.dart';
import 'services/fcm_service.dart';

final ValueNotifier<Locale?> appLocaleNotifier = ValueNotifier(null);

/// Handler de background do FCM — Anotado com @pragma('vm:entry-point')
@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  try {
    await Firebase.initializeApp();
  } catch (e) {
    debugPrint('⚠️ [FCM Background] Firebase já inicializado: $e');
  }

  if (message.data["type"] == "DATABASE_CHANGE") {
    try {
      debugPrint('🔔 [FCM Background] Mudança na BD detetada! A acionar pull sync em background...');
      await SyncManager.instance.executePullSync();
    } catch (e) {
      debugPrint('❌ [FCM Background] Erro ao executar pull sync: $e');
    }
  }
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // 1. Inicializar Firebase
  try {
    await Firebase.initializeApp();
  } catch (e) {
    debugPrint('⚠️ [main] Firebase.initializeApp() — instância já existia: $e');
  }

  // 2. Registar o handler de background do FCM
  FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

  // 3. Forçar criação/abertura da base de dados local SQLite
  await DatabaseHelper.instance.database;

  // 4. Inicializar o AuthController (await para evitar condições de corrida)
  await AuthController.instance.initialize();

  // 5. Inicialização silenciosa de sincronização em background se já autenticado
  try {
    final jwtToken = await SecureStorage.getToken();
    if (jwtToken != null) {
      FcmService.instance.inicializarListeners();
      SyncManager.instance.executePullSync().catchError((e) {
        debugPrint('⚠️ [SyncManager] Erro silencioso no Pull Sync inicial: $e');
        return false;
      });
    }
  } catch (e) {
    debugPrint('⚠️ [main] Falha ao configurar sincronização em background: $e');
  }

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