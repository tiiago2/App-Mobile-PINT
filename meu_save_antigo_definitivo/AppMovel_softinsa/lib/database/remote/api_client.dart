import 'dart:io';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';
import '../local/secure_storage.dart';
import '../../services/session_storage.dart';
import 'package:flutter/material.dart';
import '../../controllers/auth_controller.dart';
import '../../routes/routes_app.dart';

class ApiClient {
  // âš ï¸ URL real do backend mobile (incluindo o prefixo /api/mobile)
  static const String baseUrl = 'https://pint-he77.onrender.com/api/mobile';
  late final Dio _dio;

  ApiClient() {
    _dio = Dio(BaseOptions(
      baseUrl: baseUrl,
      connectTimeout: const Duration(seconds: 15),
      receiveTimeout: const Duration(seconds: 15),
      sendTimeout: const Duration(seconds: 15),
    ));

    // Este intercetor injeta o token automaticamente em todos os pedidos protegidos
    _dio.interceptors.add(QueuedInterceptorsWrapper(
      onRequest: (options, handler) async {
        // Rotas públicas que NÃO precisam de token de acesso
        final isPublic = options.path.contains('/health') || 
                         options.path.contains('/auth/login') ||
                         options.path.contains('/auth/refresh');
                         
        if (!isPublic) {
          final token = await SecureStorage.getToken();
          if (token != null) {
            options.headers['Authorization'] = 'Bearer $token';
          }
        }
        return handler.next(options);
      },
      onError: (e, handler) async {
        final isPublic = e.requestOptions.path.contains('/health') || 
                         e.requestOptions.path.contains('/auth/login') ||
                         e.requestOptions.path.contains('/auth/refresh');
        if (e.response?.statusCode == 401 && !isPublic) {
          // Trava contra loop de retentativas
          if (e.requestOptions.extra['retried'] == true) {
            return handler.next(e);
          }
          e.requestOptions.extra['retried'] = true;

          final currentStoredToken = await SecureStorage.getToken();
          final requestToken = e.requestOptions.headers['Authorization']
              ?.toString()
              .replaceFirst('Bearer ', '');

          // Se o token na BD local já for diferente do token enviado,
          // significa que outra requisição concorrente já fez o refresh com sucesso!
          if (currentStoredToken != null && currentStoredToken != requestToken) {
            debugPrint('🔑 [ApiClient] Token já renovado concorrentemente. A re-enviar pedido...');
            e.requestOptions.headers['Authorization'] = 'Bearer $currentStoredToken';

            if (e.requestOptions.data is FormData) {
              e.requestOptions.data = await _clonarFormData(e.requestOptions.data as FormData, e.requestOptions);
            }

            final cleanDio = Dio(BaseOptions(
              baseUrl: _dio.options.baseUrl,
              connectTimeout: const Duration(seconds: 15),
              receiveTimeout: const Duration(seconds: 15),
              sendTimeout: const Duration(seconds: 15),
            ));

            try {
              final response = await cleanDio.fetch(e.requestOptions);
              return handler.resolve(response);
            } catch (err) {
              if (err is DioException) {
                return handler.next(err);
              }
              return handler.next(e);
            }
          }

          debugPrint('🔑 [ApiClient] Token expirado (401). A tentar renovar com Refresh Token...');
          final session = await SessionStorage.instance.readTokens();
          final refreshToken = session?.refreshToken;
          if (refreshToken != null && refreshToken.isNotEmpty) {
            bool refreshSucceeded = false;
            try {
              // Realizar o refresh chamando o endpoint /auth/refresh
              final refreshResponse = await refresh(refreshToken);
              if (refreshResponse != null && refreshResponse['success'] == true) {
                final newAccessToken = refreshResponse['token'] ?? refreshResponse['access_token'] ?? refreshResponse['data']?['token'];
                final newRefreshToken = refreshResponse['refreshToken'] ?? refreshResponse['refresh_token'] ?? refreshResponse['data']?['refresh_token'];

                if (newAccessToken != null && newAccessToken.toString().isNotEmpty) {
                  debugPrint('🔑 [ApiClient] Refresh bem-sucedido! A guardar novos tokens.');
                  await SecureStorage.saveToken(newAccessToken.toString());
                  if (newRefreshToken != null) {
                    await SessionStorage.instance.saveTokens(
                      accessToken: newAccessToken.toString(),
                      refreshToken: newRefreshToken.toString(),
                    );
                  }

                  // Atualizar o cabeçalho do pedido original com o novo token
                  e.requestOptions.headers['Authorization'] = 'Bearer $newAccessToken';
                  
                  // Clonar FormData se necessário para evitar erros com MultipartFile
                  if (e.requestOptions.data is FormData) {
                    e.requestOptions.data = await _clonarFormData(e.requestOptions.data as FormData, e.requestOptions);
                  }

                  // Repetir a requisição utilizando uma instância limpa de Dio (evita Deadlock)
                  final cleanDio = Dio(BaseOptions(
                    baseUrl: _dio.options.baseUrl,
                    connectTimeout: const Duration(seconds: 15),
                    receiveTimeout: const Duration(seconds: 15),
                    sendTimeout: const Duration(seconds: 15),
                  ));

                  try {
                    final response = await cleanDio.fetch(e.requestOptions);
                    refreshSucceeded = true;
                    return handler.resolve(response);
                  } catch (retryError) {
                    if (retryError is DioException) {
                      return handler.next(retryError);
                    }
                    return handler.next(e);
                  }
                }
              }
            } catch (refreshErr) {
              debugPrint('❌ [ApiClient] Erro durante o refresh do token: $refreshErr');
            }

            if (!refreshSucceeded) {
              debugPrint('❌ [ApiClient] Falha na renovação do token. A efetuar logout...');
              await AuthController.instance.logout();

              final context = AppRoutes.rootNavigatorKey.currentContext;
              if (context != null && context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('A sua sessão expirou. Por favor, faça login novamente.'),
                    backgroundColor: Colors.red,
                  ),
                );
              }
            }
          }
        }
        return handler.next(e);
      },
    ));
  }

  // ================= 1. ROTAS PÃšBLICAS =================

  /// Health Check: GET /api/mobile/health
  Future<bool> checkHealth() async {
    try {
      final response = await _dio.get('/health');
      return response.statusCode == 200;
    } catch (_) {
      return false;
    }
  }

  /// Login: POST /api/mobile/auth/login
  Future<Map<String, dynamic>?> login(String email, String password, String deviceId) async {
    try {
      final response = await _dio.post('/auth/login', data: {
        'email': email,
        'password': password,
        'device_id': deviceId,
      });
      return response.data;
    } catch (e) {
      debugPrint('âŒ Erro no Login: $e');
      return null;
    }
  }

  /// Token Refresh: POST /api/mobile/auth/refresh
  Future<Map<String, dynamic>?> refresh(String refreshToken) async {
    try {
      final deviceId = await SecureStorage.getDeviceId() ?? 'dispositivo_flutter_1';
      final response = await _dio.post('/auth/refresh', data: {
        'refresh_token': refreshToken,
        'device_id': deviceId,
      });
      return response.data;
    } catch (e) {
      debugPrint('❌ Erro no Refresh de Token: $e');
      return null;
    }
  }

  /// Logout: POST /api/mobile/auth/logout
  Future<Map<String, dynamic>?> logout(String refreshToken, String deviceId) async {
    try {
      final response = await _dio.post('/auth/logout', data: {
        'refresh_token': refreshToken,
        'device_id': deviceId,
      });
      return response.data;
    } catch (e) {
      debugPrint('âŒ Erro no Logout: $e');
      return null;
    }
  }

  // ================= 2. ROTAS PROTEGIDAS =================

  /// Obter Perfil: GET /api/mobile/auth/me
  Future<Map<String, dynamic>?> getMe() async {
    try {
      final response = await _dio.get('/auth/me');
      return response.data;
    } catch (e) {
      debugPrint('âŒ Erro ao obter perfil (/auth/me): $e');
      return null;
    }
  }

  /// Registar/Atualizar Token FCM via Dio: PUT /api/mobile/devices
  Future<bool> registerDeviceToken(String fcmToken, String deviceId) async {
    try {
      final platform = Platform.isAndroid ? 'android' : (Platform.isIOS ? 'ios' : 'web');
      final response = await _dio.put('/devices', data: {
        'fcm_token': fcmToken,
        'device_id': deviceId,
        'platform': platform,
      });
      return response.statusCode == 200 || response.statusCode == 201;
    } catch (e) {
      debugPrint('âŒ Erro ao registar FCM token no servidor: $e');
      return false;
    }
  }

  /// Alias para atualizar token FCM
  Future<Map<String, dynamic>?> updateFcmToken(String fcmToken, String platform) async {
    try {
      final response = await _dio.put('/devices', data: {
        'fcm_token': fcmToken,
        'platform': platform,
      });
      return response.data;
    } catch (e) {
      debugPrint('âŒ Erro ao atualizar FCM Token: $e');
      return null;
    }
  }

  /// Remover Dispositivo: DELETE /api/mobile/devices/:deviceId
  Future<Map<String, dynamic>?> deleteDevice(String deviceId) async {
    try {
      final response = await _dio.delete('/devices/$deviceId');
      return response.data;
    } catch (e) {
      debugPrint('âŒ Erro ao remover dispositivo: $e');
      return null;
    }
  }

  // ================= 3. PULL SYNC (Download) =================
  Future<Map<String, dynamic>?> pullSync({String? since}) async {
    final Map<String, dynamic> query = since != null ? {'since': since} : {};
    try {
      final response = await _dio.get('/pull', queryParameters: query);
      return response.data;
    } on DioException catch (e) {
      if (e.response?.statusCode == 404) {
        try {
          final response = await _dio.get('/sync', queryParameters: query);
          return response.data;
        } on DioException catch (innerErr) {
          debugPrint('âŒ Erro no Pull Sync (/sync): [${innerErr.response?.statusCode}] ${innerErr.response?.data}');
          return null;
        }
      }
      debugPrint('âŒ Erro no Pull Sync (/pull): [${e.response?.statusCode}] ${e.response?.data}');
      return null;
    } catch (e) {
      debugPrint('âŒ Erro inesperado no Pull Sync: $e');
      return null;
    }
  }

  // ================= 3b. HISTÃ“RICO DE SUBMISSÃƒO =================
  /// Tenta buscar o histÃ³rico (feedback) de uma submissÃ£o especÃ­fica.
  /// Experimenta mÃºltiplos padrÃµes de endpoint REST atÃ© obter resposta.
  /// Retorna a lista de entradas de histÃ³rico ou null se nÃ£o suportado.
  Future<List<Map<String, dynamic>>?> fetchHistoricoSubmissao(int idSubmissao) async {
    final endpoints = [
      '/submissoes/$idSubmissao/historico',
      '/candidaturas/$idSubmissao/historico',
      '/submissions/$idSubmissao/historico',
      '/submissions/$idSubmissao/history',
      '/historico?submissao_id=$idSubmissao',
      '/historico_candidatura?id_submissao=$idSubmissao',
    ];
    for (final path in endpoints) {
      try {
        final response = await _dio.get(path);
        if (response.statusCode == 200) {
          final body = response.data;
          if (body is List) return List<Map<String, dynamic>>.from(body);
          if (body is Map) {
            final data = body['data'] ?? body['historico'] ?? body['historico_candidatura'] ?? body['items'];
            if (data is List) return List<Map<String, dynamic>>.from(data);
          }
        }
      } on DioException catch (e) {
        // 404 = endpoint nÃ£o existe, tentar prÃ³ximo
        if (e.response?.statusCode != 404 && e.response?.statusCode != 405) {
          debugPrint('âš ï¸ [ApiClient] fetchHistoricoSubmissao $path: ${e.response?.statusCode}');
        }
      } catch (_) {}
    }
    return null;
  }

  // ================= 4. PUSH SYNC (Upload de Dados) =================
  Future<Map<String, dynamic>?> pushSync(Map<String, dynamic> payloadBatch) async {
    try {
      final response = await _dio.post('/push', data: payloadBatch);
      return response.data;
    } on DioException catch (e) {
      debugPrint('âŒ Erro no Push Sync (/push): [${e.response?.statusCode}] ${e.response?.data}');
      return null;
    } catch (e) {
      debugPrint('âŒ Erro inesperado no Push Sync: $e');
      return null;
    }
  }

  // ================= 5. UPLOAD DE DOCUMENTOS =================
  /// Upload de Evidências: POST /api/mobile/upload
  Future<Map<String, dynamic>?> uploadDocument(String filePath, [Map<String, dynamic> additionalFields = const {}]) async {
    try {
      final file = File(filePath);
      if (!await file.exists()) {
        throw Exception('Ficheiro de evidência não existe no caminho local: $filePath');
      }

      final fileName = filePath.split(Platform.pathSeparator).last;
      final formData = FormData.fromMap({
        'ficheiro': await MultipartFile.fromFile(filePath, filename: fileName),
        ...additionalFields,
      });

      print('--- 🚨 INÍCIO DO UPLOAD MULTIPART ---');
      print('ID SUBMISSÃO ENVIADO: ${formData.fields.firstWhere((f) => f.key == 'id_submissao', orElse: () => MapEntry('id_submissao', 'N/A')).value}');
      print('ID REQUISITO ENVIADO: ${formData.fields.firstWhere((f) => f.key == 'id_requisito', orElse: () => MapEntry('id_requisito', 'N/A')).value}');

      final response = await _dio.post(
        '/upload',
        data: formData,
        options: Options(
          contentType: 'multipart/form-data',
          extra: {'file_path': filePath},
        ),
      );
      return response.data;
    } on DioException catch (e) {
      print('--- 💥 ERRO NO SERVIDOR (UPLOAD) ---');
      print('STATUS CODE: ${e.response?.statusCode}');
      print('CORPO DA RESPOSTA: ${e.response?.data}');
      print('MENSAGEM: ${e.message}');
      debugPrint('❌ Erro no Upload de Documento (/upload): [${e.response?.statusCode}] ${e.response?.data}');
      return null;
    } catch (e) {
      print('💥 ERRO DESCONHECIDO: $e');
      debugPrint('❌ Erro inesperado no Upload: $e');
      return null;
    }
  }

  /// Alias para compatibilidade anterior
  Future<Map<String, dynamic>?> uploadEvidence(String filePath, Map<String, dynamic> additionalFields) async {
    return uploadDocument(filePath, additionalFields);
  }

  /// Upload de Foto de Perfil: PUT /api/utilizadores/:id
  Future<String?> uploadProfilePicture(int userId, String filePath) async {
    try {
      final file = File(filePath);
      if (!await file.exists()) {
        throw Exception('Ficheiro não encontrado localmente: $filePath');
      }

      final fileName = filePath.split(Platform.pathSeparator).last;
      final formData = FormData.fromMap({
        'imagem': await MultipartFile.fromFile(filePath, filename: fileName),
      });

      final response = await _dio.put(
        'https://pint-he77.onrender.com/api/utilizadores/$userId',
        data: formData,
        options: Options(
          contentType: 'multipart/form-data',
          extra: {'file_path': filePath},
        ),
      );

      if (response.statusCode == 200) {
        final data = response.data;
        if (data is Map<String, dynamic>) {
          return data['imagem_perfil']?.toString() ?? data['foto']?.toString();
        }
      }
      return null;
    } on DioException catch (e) {
      debugPrint('❌ Erro no Upload de Foto de Perfil: [${e.response?.statusCode}] ${e.response?.data}');
      return null;
    } catch (e) {
      debugPrint('❌ Erro inesperado no upload da foto: $e');
      return null;
    }
  }

  /// Upload de foto de perfil com estratégia de fallback:
  /// 1. Tenta o endpoint mobile dedicado: PUT /api/mobile/perfil/foto
  /// 2. Se falhar ou não retornar URL, tenta o endpoint principal: PUT /api/utilizadores/:id
  Future<String?> uploadProfilePhotoOffline(int userId, String filePath) async {
    final file = File(filePath);
    if (!await file.exists()) {
      debugPrint('❌ [uploadProfilePhotoOffline] Ficheiro não encontrado: $filePath');
      return null;
    }

    // Helper: extrai URL de um Map tentando todos os campos conhecidos (recursivo 1 nível)
    String? extrairUrl(dynamic data) {
      if (data is! Map<String, dynamic>) return null;
      // Campos diretos
      for (final field in ['url', 'secure_url', 'foto', 'imagem_perfil', 'imagem', 'photo_url', 'file_url', 'path']) {
        final v = data[field]?.toString();
        if (v != null && v.startsWith('http')) return v;
      }
      // Campos dentro de 'data' aninhado
      final nested = data['data'];
      if (nested is Map<String, dynamic>) {
        for (final field in ['url', 'secure_url', 'foto', 'imagem_perfil', 'imagem', 'photo_url', 'file_url']) {
          final v = nested[field]?.toString();
          if (v != null && v.startsWith('http')) return v;
        }
      }
      return null;
    }

    // --- Tentativa 1: endpoint mobile dedicado /perfil/foto ---
    try {
      debugPrint('📤 [uploadProfilePhotoOffline] Tentativa 1: PUT /perfil/foto');
      final formData1 = FormData.fromMap({
        'foto': await MultipartFile.fromFile(filePath, filename: 'profile_photo.jpg'),
      });

      final response1 = await _dio.put(
        '/perfil/foto',
        data: formData1,
        options: Options(
          contentType: 'multipart/form-data',
          extra: {'file_path': filePath},
          sendTimeout: const Duration(seconds: 30),
          receiveTimeout: const Duration(seconds: 30),
        ),
      );

      debugPrint('🔍 [uploadProfilePhotoOffline] Tentativa 1 resposta completa: ${response1.data}');

      if (response1.statusCode == 200) {
        final url = extrairUrl(response1.data);
        if (url != null) {
          debugPrint('✅ [uploadProfilePhotoOffline] Tentativa 1 bem-sucedida: $url');
          return url;
        }
        debugPrint('⚠️ [uploadProfilePhotoOffline] Tentativa 1 retornou 200 mas sem URL reconhecível. Corpo: ${response1.data}. A tentar fallback...');
      } else {
        debugPrint('⚠️ [uploadProfilePhotoOffline] Tentativa 1 retornou código ${response1.statusCode}. A tentar fallback...');
      }
    } on DioException catch (e) {
      debugPrint('⚠️ [uploadProfilePhotoOffline] Tentativa 1 falhou: [${e.response?.statusCode}] ${e.response?.data}. A tentar fallback...');
    } catch (e) {
      debugPrint('⚠️ [uploadProfilePhotoOffline] Tentativa 1 erro inesperado: $e. A tentar fallback...');
    }

    // --- Tentativa 2: endpoint principal /api/utilizadores/:id ---
    // Usa token fresco explicitamente para evitar problemas com URL absoluto
    try {
      debugPrint('📤 [uploadProfilePhotoOffline] Tentativa 2 (fallback): PUT /api/utilizadores/$userId');
      final token = await SecureStorage.getToken();
      final fileName = filePath.split(Platform.pathSeparator).last;
      final formData2 = FormData.fromMap({
        'imagem': await MultipartFile.fromFile(filePath, filename: fileName),
        'foto': await MultipartFile.fromFile(filePath, filename: fileName),
      });

      final response2 = await _dio.put(
        'https://pint-he77.onrender.com/api/utilizadores/$userId',
        data: formData2,
        options: Options(
          contentType: 'multipart/form-data',
          extra: {'file_path': filePath},
          sendTimeout: const Duration(seconds: 30),
          receiveTimeout: const Duration(seconds: 30),
          headers: token != null ? {'Authorization': 'Bearer $token'} : null,
        ),
      );

      debugPrint('🔍 [uploadProfilePhotoOffline] Tentativa 2 resposta completa: ${response2.data}');

      if (response2.statusCode == 200) {
        final url = extrairUrl(response2.data);
        if (url != null) {
          debugPrint('✅ [uploadProfilePhotoOffline] Tentativa 2 bem-sucedida: $url');
          return url;
        }
        debugPrint('❌ [uploadProfilePhotoOffline] Tentativa 2 retornou 200 mas sem URL. Corpo: ${response2.data}');
      } else {
        debugPrint('❌ [uploadProfilePhotoOffline] Tentativa 2 falhou. Código: ${response2.statusCode}. Resposta: ${response2.data}');
      }
    } on DioException catch (e) {
      debugPrint('❌ [uploadProfilePhotoOffline] Tentativa 2 (fallback) falhou: [${e.response?.statusCode}] ${e.response?.data}');
    } catch (e) {
      debugPrint('❌ [uploadProfilePhotoOffline] Tentativa 2 erro inesperado: $e');
    }

    return null;
  }

  Future<FormData> _clonarFormData(FormData original, RequestOptions options) async {
    final clone = FormData();
    clone.fields.addAll(original.fields);
    
    final String? filePath = options.extra['file_path'] as String?;
    
    for (final entry in original.files) {
      if (filePath != null && filePath.isNotEmpty) {
        clone.files.add(MapEntry(
          entry.key,
          await MultipartFile.fromFile(
            filePath,
            filename: entry.value.filename,
            contentType: entry.value.contentType,
          ),
        ));
      } else {
        clone.files.add(entry);
      }
    }
    return clone;
  }

  Future<bool> atualizarLastLogin(int userId) async {
    try {
      final response = await _dio.put(
        'https://pint-he77.onrender.com/api/putlastlogin',
        data: {'id': userId},
      );
      return response.statusCode == 200 || response.statusCode == 201;
    } catch (e) {
      debugPrint('❌ [ApiClient] Erro ao atualizar last login no servidor: $e');
      return false;
    }
  }

  /// Descarrega um ficheiro de forma segura com autenticação Bearer.
  /// Guarda o ficheiro no caminho local especificado e retorna o caminho do ficheiro guardado.
  Future<String?> downloadFile(String fileUrl, {String? customFileName}) async {
    try {
      final token = await SecureStorage.getToken();
      final tempDir = await getTemporaryDirectory();
      final cleanUrl = fileUrl.trim();
      final fileName = customFileName ?? cleanUrl.split('/').last.split('?').first;
      final savePath = '${tempDir.path}/$fileName';

      debugPrint('📥 [ApiClient] A descarregar ficheiro: $cleanUrl -> $savePath');

      final response = await _dio.download(
        cleanUrl,
        savePath,
        options: Options(
          headers: token != null ? {'Authorization': 'Bearer $token'} : null,
          receiveTimeout: const Duration(seconds: 45),
        ),
      );

      if (response.statusCode == 200) {
        debugPrint('✅ [ApiClient] Ficheiro descarregado com sucesso: $savePath');
        return savePath;
      }
    } catch (e) {
      debugPrint('❌ [ApiClient] Erro ao descarregar ficheiro: $e');
    }
    return null;
  }
}
