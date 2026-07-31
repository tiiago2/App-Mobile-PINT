import 'dart:io';
import 'package:dio/dio.dart';
import '../local/secure_storage.dart';

class ApiClient {
  // ⚠️ URL real do backend mobile (incluindo o prefixo /api/mobile)
  static const String baseUrl = 'https://pint-he77.onrender.com/api/mobile';
  
  late final Dio _dio;

  ApiClient() {
    _dio = Dio(BaseOptions(
      baseUrl: baseUrl,
      connectTimeout: const Duration(seconds: 15),
      receiveTimeout: const Duration(seconds: 15),
    ));

    // Este intercetor injeta o token automaticamente em todos os pedidos protegidos
    _dio.interceptors.add(InterceptorsWrapper(
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
    ));
  }

  // ================= 1. ROTAS PÚBLICAS =================

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
      print('❌ Erro no Login: $e');
      return null;
    }
  }

  /// Token Refresh: POST /api/mobile/auth/refresh
  Future<Map<String, dynamic>?> refresh(String refreshToken) async {
    try {
      final response = await _dio.post('/auth/refresh', data: {
        'refresh_token': refreshToken,
      });
      return response.data;
    } catch (e) {
      print('❌ Erro no Refresh de Token: $e');
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
      print('❌ Erro no Logout: $e');
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
      print('❌ Erro ao obter perfil (/auth/me): $e');
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
      print('❌ Erro ao registar FCM token no servidor: $e');
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
      print('❌ Erro ao atualizar FCM Token: $e');
      return null;
    }
  }

  /// Remover Dispositivo: DELETE /api/mobile/devices/:deviceId
  Future<Map<String, dynamic>?> deleteDevice(String deviceId) async {
    try {
      final response = await _dio.delete('/devices/$deviceId');
      return response.data;
    } catch (e) {
      print('❌ Erro ao remover dispositivo: $e');
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
          print('❌ Erro no Pull Sync (/sync): [${innerErr.response?.statusCode}] ${innerErr.response?.data}');
          return null;
        }
      }
      print('❌ Erro no Pull Sync (/pull): [${e.response?.statusCode}] ${e.response?.data}');
      return null;
    } catch (e) {
      print('❌ Erro inesperado no Pull Sync: $e');
      return null;
    }
  }

  // ================= 4. PUSH SYNC (Upload de Dados) =================
  Future<Map<String, dynamic>?> pushSync(Map<String, dynamic> payloadBatch) async {
    try {
      final response = await _dio.post('/push', data: payloadBatch);
      return response.data;
    } on DioException catch (e) {
      print('❌ Erro no Push Sync (/push): [${e.response?.statusCode}] ${e.response?.data}');
      return null;
    } catch (e) {
      print('❌ Erro inesperado no Push Sync: $e');
      return null;
    }
  }

  // ================= 5. UPLOAD DE DOCUMENTOS =================
  /// Upload de Evidências: POST /api/mobile/upload
  Future<Map<String, dynamic>?> uploadDocument(String filePath, Map<String, dynamic> additionalFields) async {
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

      final response = await _dio.post(
        '/upload',
        data: formData,
        options: Options(contentType: 'multipart/form-data'),
      );
      return response.data;
    } on DioException catch (e) {
      print('❌ Erro no Upload de Documento (/upload): [${e.response?.statusCode}] ${e.response?.data}');
      return null;
    } catch (e) {
      print('❌ Erro inesperado no Upload: $e');
      return null;
    }
  }

  /// Alias para compatibilidade anterior
  Future<Map<String, dynamic>?> uploadEvidence(String filePath, Map<String, dynamic> additionalFields) async {
    return uploadDocument(filePath, additionalFields);
  }
}