import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class SecureStorage {
  static const _storage = FlutterSecureStorage();

  static const _keyToken = 'access_token';
  static const _keyDeviceId = 'device_id';

  // Guardar e Ler Token
  static Future<void> saveToken(String token) async {
    await _storage.write(key: _keyToken, value: token);
  }

  static Future<String?> getToken() async {
    return await _storage.read(key: _keyToken);
  }

  static Future<void> deleteToken() async {
    await _storage.delete(key: _keyToken);
  }

  // Guardar e Ler Device ID
  static Future<void> saveDeviceId(String id) async {
    await _storage.write(key: _keyDeviceId, value: id);
  }

  static Future<String?> getDeviceId() async {
    return await _storage.read(key: _keyDeviceId);
  }
}