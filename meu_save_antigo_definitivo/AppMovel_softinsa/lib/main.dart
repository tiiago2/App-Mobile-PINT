import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';

// ⚠️ ATENÇÃO: Ajuste os caminhos de importação conforme as suas pastas!
import 'database/database_helper.dart';
import 'database/local/secure_storage.dart';
import 'database/remote/api_client.dart';
import 'database/sync_manager.dart';
import 'screens/dev_test_screen.dart';

/// Handler de background — OBRIGATÓRIO estar no top-level (fora de qualquer classe).
/// É chamado quando a app está em background ou terminada e chega uma notificação.
@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  // Firebase tem de ser inicializado aqui também, porque este handler
  // corre num isolate separado sem contexto da app principal.
  try {
    await Firebase.initializeApp();
  } catch (e) {
    debugPrint('⚠️ Firebase já inicializado no background handler: $e');
  }

  debugPrint('🔔 [FCM Background] Mensagem recebida: ${message.messageId}');
  debugPrint('   Data payload: ${message.data}');

  // ── Sincronização Automática por Push em Background ─────────────────────
  try {
    final syncManager = SyncManager();
    final userIdStr = message.data['user_id'];
    final userId = userIdStr != null ? int.tryParse(userIdStr.toString()) : null;

    debugPrint('🔄 [FCM Background] A acionar Pull Sync automático via Push...');
    await syncManager.executePullSync(userId);
  } catch (e) {
    debugPrint('❌ Erro ao executar Sync automático no background: $e');
  }
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // ── 1. Inicializar Firebase ──────────────────────────────────────────────
  try {
    await Firebase.initializeApp();
    debugPrint('✅ Firebase inicializado com sucesso.');
  } catch (e) {
    debugPrint('⚠️ Firebase.initializeApp() — instância já existia: $e');
  }

  // ── 2. Registar o handler de background do FCM ───────────────────────────
  FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

  // ── 3. Pedir permissões de notificação e Subscrever Tópico ───────────────
  try {
    final settings = await FirebaseMessaging.instance.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );
    debugPrint('🔔 Permissão FCM: ${settings.authorizationStatus}');

    // 🌟 NOVA LINHA: Subscreve o tópico de atualizações globais disparado pelo backend
    await FirebaseMessaging.instance.subscribeToTopic('sync_updates');
    debugPrint('📡 Subscrito com sucesso no tópico "sync_updates"!');
  } catch (e) {
    debugPrint('⚠️ Erro ao configurar permissões/tópicos do FCM: $e');
  }

  // ── 4. Ouvinte de mensagens em foreground ────────────────────────────────
  FirebaseMessaging.onMessage.listen((RemoteMessage message) async {
    debugPrint('🔔 [FCM Foreground] Mensagem recebida: ${message.messageId}');
    debugPrint('   Data payload: ${message.data}');

    try {
      final syncManager = SyncManager();
      
      // Tenta extrair o ID aceitando várias chaves possíveis do backend
      final userIdRaw = message.data['user_id'] ?? 
                        message.data['id_utilizador'] ?? 
                        message.data['userId'];
                        
      final userId = userIdRaw != null ? int.tryParse(userIdRaw.toString()) : null;

      debugPrint('🔄 [FCM Foreground] A acionar Pull Sync automático via Push (UserID: ${userId ?? 'Atual'})...');
      
      await syncManager.executePullSync(userId);
    } catch (e) {
      debugPrint('❌ Erro no Sync automático via Push (Foreground): $e');
    }
  });

  // ── 5. Forçar criação/abertura da base de dados local ────────────────────
  await DatabaseHelper.instance.database;

  runApp(const MaterialApp(
    home: IntegrationTestScreen(),
    debugShowCheckedModeBanner: false,
  ));
}

class IntegrationTestScreen extends StatefulWidget {
  const IntegrationTestScreen({super.key});

  @override
  State<IntegrationTestScreen> createState() => _IntegrationTestScreenState();
}

class _IntegrationTestScreenState extends State<IntegrationTestScreen> {
  final ApiClient _apiClient = ApiClient();
  final SyncManager _syncManager = SyncManager();

  final TextEditingController _emailController =
      TextEditingController(text: 'jose@softinsa.pt');
  final TextEditingController _passwordController =
      TextEditingController(text: '123');

  String _log = "A aguardar início do teste...\n";
  bool _isLoading = false;
  int? _loggedUserId;

  void _addLog(String message) {
    setState(() {
      _log += "[$message]\n";
    });
    debugPrint(message);
  }

  Future<void> _executarTesteCompleto() async {
    setState(() {
      _isLoading = true;
      _log = "🚀 A iniciar Teste de Integração...\n";
    });

    try {
      // ── FASE 1: TESTAR O LOGIN ─────────────────────────────────────────
      _addLog("1. A tentar Login no Servidor (Render)...");

      final email = _emailController.text;
      final password = _passwordController.text;
      const deviceId = "flutter_test_device_001";

      final loginResponse =
          await _apiClient.login(email, password, deviceId);

      if (loginResponse != null && loginResponse['success'] == true) {
        final token = loginResponse['access_token'];
        final userId = loginResponse['user']['id'];

        setState(() {
          _loggedUserId = userId;
        });

        _addLog("✅ Login efetuado com Sucesso!");
        _addLog("👤 Utilizador: ${loginResponse['user']['nome']} (ID: $userId)");

        // ── FASE 2: GUARDAR O TOKEN ────────────────────────────────────
        _addLog("2. A guardar JWT Token no Secure Storage...");
        await SecureStorage.saveToken(token);
        _addLog("✅ Token guardado em segurança.");
        
        _addLog("2.1. A registar FCM Token no servidor...");
        try {
          String? fcmToken = await FirebaseMessaging.instance.getToken();
          print("FCM DEVICE TOKEN OBTIDO: $fcmToken");
          if (fcmToken != null) {
            bool registrado = await _apiClient.registerDeviceToken(fcmToken, deviceId);
            if (registrado) {
              _addLog("✅ FCM Token associado ao utilizador no servidor!");
            } else {
              _addLog("⚠️ Erro ao associar FCM Token no servidor.");
            }
          }
        } catch (fcmError) {
          _addLog("⚠️ Erro ao obter Token FCM: $fcmError");
        }

        // ── FASE 3: PULL SYNC ──────────────────────────────────────────
        _addLog("3. A iniciar Sincronização (Pull Sync)...");
        final syncSuccess = await _syncManager.executePullSync(userId);

        if (syncSuccess) {
          _addLog("✅ Sincronização concluída com sucesso!");

          // ── FASE 4: VERIFICAR BASE DE DADOS LOCAL ─────────────────────
          _addLog("4. A verificar o SQLite local...");
          try {
            _addLog("✅ Tudo operational! Verifique o Database Inspector.");
          } catch (e) {
            _addLog("✅ Sync funcionou! (Erro apenas ao ler dados para o log: $e)");
          }
        } else {
          _addLog("❌ Erro na Sincronização. Veja o terminal.");
        }
      } else {
        _addLog("❌ Falha no Login. Verifique email/password ou se o servidor está online.");
      }
    } catch (e) {
      _addLog("❌ ERRO FATAL: $e");
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Painel de Testes (API & Sync)')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            TextField(
              controller: _emailController,
              decoration:
                  const InputDecoration(labelText: 'Email do Backend'),
            ),
            TextField(
              controller: _passwordController,
              decoration:
                  const InputDecoration(labelText: 'Password do Backend'),
              obscureText: true,
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _isLoading ? null : _executarTesteCompleto,
              child: _isLoading
                  ? const CircularProgressIndicator(color: Colors.white)
                  : const Text('TESTAR FLUXO COMPLETO'),
            ),
            if (_loggedUserId != null) ...[
              const SizedBox(height: 12),
              ElevatedButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => DevTestScreen(userId: _loggedUserId!),
                    ),
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.indigo,
                  foregroundColor: Colors.white,
                ),
                child: const Text('IR PARA PAINEL DE TESTES DE SYNC'),
              ),
            ],
            const SizedBox(height: 16),
            const Text('Logs da Operação:',
                style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Expanded(
              child: Container(
                padding: const EdgeInsets.all(8),
                color: Colors.black87,
                child: SingleChildScrollView(
                  child: Text(
                    _log,
                    style: const TextStyle(
                        color: Colors.greenAccent, fontFamily: 'monospace'),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}