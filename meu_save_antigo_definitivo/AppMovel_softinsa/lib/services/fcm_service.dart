import 'package:dio/dio.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import '../database/remote/api_client.dart';
import '../database/sync_manager.dart';
import '../database/local/secure_storage.dart';

class FcmService {
  FcmService._();
  static final FcmService instance = FcmService._();

  /// Solicita permissões de notificação e obtém o Device Token inicial.
  Future<void> inicializarFCM() async {
    try {
      // 1. Solicitar permissões ao utilizador
      final settings = await FirebaseMessaging.instance.requestPermission(
        alert: true,
        announcement: false,
        badge: true,
        carPlay: false,
        criticalAlert: false,
        provisional: false,
        sound: true,
      );

      print('🔔 [FCM Service] Estado da permissão: ${settings.authorizationStatus}');

      if (settings.authorizationStatus == AuthorizationStatus.authorized ||
          settings.authorizationStatus == AuthorizationStatus.provisional) {
        
        // 2. Obter FCM token inicial
        final token = await FirebaseMessaging.instance.getToken();
        if (token != null) {
          print('🔑 [FCM Service] FCM Device Token inicial obtido: $token');
          await registarTokenNoServidor(token);
        }

        // 3. Escutar atualização de token (onTokenRefresh)
        FirebaseMessaging.instance.onTokenRefresh.listen((newToken) async {
          print('🔄 [FCM Service] FCM Token renovado: $newToken');
          await registarTokenNoServidor(newToken);
        });

        // 4. Subscrever no tópico de sincronização global
        await FirebaseMessaging.instance.subscribeToTopic("sync_updates");
        print('✅ [FCM Service] Subscrição no tópico "sync_updates" concluída.');
      }
    } catch (e) {
      print('❌ [FCM Service] Erro ao inicializar FCM: $e');
    }
  }

  /// Inicializa os listeners para mensagens recebidas em foreground (primeiro plano).
  void inicializarListeners() {
    FirebaseMessaging.onMessage.listen((RemoteMessage message) async {
      print('📩 [FCM Service] Mensagem recebida em Foreground: ${message.messageId}');
      
      // Verificar se a mensagem indica alteração na base de dados
      if (message.data['type'] == 'DATABASE_CHANGE') {
        print('🔔 [FCM Foreground] Mudança na BD detetada! A disparar pull sync automático...');
        try {
          final success = await SyncManager.instance.executePullSync();
          if (success) {
            print('✅ [FCM Foreground] Pull Sync automático concluído com sucesso.');
          } else {
            print('⚠️ [FCM Foreground] Pull Sync automático falhou.');
          }
        } catch (e) {
          print('❌ [FCM Foreground] Erro ao executar pull sync automático: $e');
        }
      }
    });
  }

  /// Envia o token FCM para o backend usando o JWT do utilizador e o Device ID.
  Future<void> registarTokenNoServidor(String token) async {
    final jwtToken = await SecureStorage.getToken();
    final deviceId = await SecureStorage.getDeviceId() ?? 'unknown_device';
    if (jwtToken == null) {
      print('⚠️ [FCM Service] JWT Token não encontrado no SecureStorage. Registo no servidor cancelado.');
      return;
    }

    // 1. Registar via ApiClient (API canónica do projeto)
    try {
      final success = await ApiClient().registerDeviceToken(token, deviceId);
      if (success) {
        print('✅ [FCM Service] FCM Device Token registado com sucesso via ApiClient.');
      } else {
        print('⚠️ [FCM Service] ApiClient.registerDeviceToken retornou falso.');
      }
    } catch (e) {
      print('❌ [FCM Service] Erro ao registar FCM token via ApiClient: $e');
    }

    // 2. Registar no endpoint específico solicitado (POST /api/mobile/users/fcm-token)
    try {
      final dio = Dio(BaseOptions(
        baseUrl: ApiClient.baseUrl,
        headers: {
          'Authorization': 'Bearer $jwtToken',
        },
      ));
      final response = await dio.post('/users/fcm-token', data: {
        'fcm_token': token,
        'device_id': deviceId,
      });
      if (response.statusCode == 200 || response.statusCode == 201) {
        print('✅ [FCM Service] FCM Token registado com sucesso no endpoint /users/fcm-token.');
      }
    } catch (e) {
      print('ℹ️ [FCM Service] Nota: Endpoint secundário /users/fcm-token retornou status: $e');
    }
  }
}
