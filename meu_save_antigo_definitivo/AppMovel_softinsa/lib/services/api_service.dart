import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;

class ApiException implements Exception {
  final int? statusCode;
  final String message;

  const ApiException({
    required this.message,
    this.statusCode,
  });

  @override
  String toString() => message;
}

class LoginApiResponse {
  final bool requiresPasswordChange;
  final String? token;
  final String? refreshToken;
  final Map<String, dynamic>? user;

  const LoginApiResponse({
    required this.requiresPasswordChange,
    this.token,
    this.refreshToken,
    this.user,
  });
}

class MeBadgesApiResponse {
  final int? idUtilizador;
  final int? idAreaConsultor;
  final List<Map<String, dynamic>> badges;

  const MeBadgesApiResponse({
    required this.idUtilizador,
    required this.idAreaConsultor,
    required this.badges,
  });
}

class ApiService {
  static const String baseUrl = 'https://pint-he77.onrender.com/api';
  static const Duration _timeout = Duration(seconds: 35);

  final http.Client _client;

  ApiService({http.Client? client}) : _client = client ?? http.Client();

  void dispose() {
    _client.close();
  }

  Future<LoginApiResponse> login({
    required String email,
    required String password,
  }) async {
    final json = await _postJson(
      '/mobile/auth/login',
      body: {
        'email': email.trim().toLowerCase(),
        'password': password,
        'device_id': 'dispositivo_flutter_1',
      },
    );

    final user = json['utilizador'] ?? json['user'];

    return LoginApiResponse(
      requiresPasswordChange: json['requiresPasswordChange'] == true,
      token: (json['token'] ?? json['access_token']) as String?,
      refreshToken: (json['refreshToken'] ?? json['refresh_token']) as String?,
      user: user is Map<String, dynamic> ? user : null,
    );
  }

  Future<String> primeiroAcesso({
    required String email,
    required String password,
    required String confirmPassword,
  }) async {
    final json = await _postJson(
      '/primeiro-acesso',
      body: {
        'email': email,
        'password': password,
        'confirmPassword': confirmPassword,
      },
    );

    return _extractMessage(json);
  }

  Future<String> esqueciPassword({
    required String email,
    required String password,
    required String confirmPassword,
  }) async {
    final json = await _postJson(
      '/esqueci-password',
      body: {
        'email': email,
        'password': password,
        'confirmPassword': confirmPassword,
      },
    );

    return _extractMessage(json);
  }

  Future<String> refreshAccessToken({
    required String refreshToken,
  }) async {
    final json = await _postJson(
      '/refresh-token',
      body: {
        'refreshToken': refreshToken,
      },
    );

    final token = json['token'];
    if (token is String && token.trim().isNotEmpty) {
      return token;
    }

    throw const ApiException(message: 'invalid_json');
  }

  Future<Map<String, dynamic>> getUser({
    required String accessToken,
  }) async {
    final json = await _getJson(
      '/getuser',
      accessToken: accessToken,
    );
    final user = json['utilizador'];

    if (user is Map<String, dynamic>) {
      return user;
    }

    throw const ApiException(message: 'invalid_json');
  }

  Future<MeBadgesApiResponse> getMeBadges({
    required String accessToken,
  }) async {
    final json = await _getJson(
      '/me/badges',
      accessToken: accessToken,
    );
    final badgesJson = json['badges'];

    if (badgesJson is! List) {
      throw const ApiException(message: 'invalid_json');
    }

    final badges = <Map<String, dynamic>>[];

    for (final item in badgesJson) {
      if (item is Map<String, dynamic> && item['id_badge'] is num) {
        badges.add(item);
      }
    }

    return MeBadgesApiResponse(
      idUtilizador: json['id_utilizador'] is num
          ? (json['id_utilizador'] as num).toInt()
          : null,
      idAreaConsultor: json['id_area_consultor'] is num
          ? (json['id_area_consultor'] as num).toInt()
          : null,
      badges: badges,
    );
  }

  Future<Map<String, dynamic>> _postJson(
    String path, {
    required Map<String, dynamic> body,
  }) async {
    final url = '$baseUrl$path';
    final payload = jsonEncode(body);
    print('🚨 [HTTP POST REQUEST] URL: $url');
    print('🚨 [HTTP POST REQUEST] PAYLOAD: $payload');

    try {
      final response = await _client
          .post(
            Uri.parse(url),
            headers: const {
              HttpHeaders.contentTypeHeader: 'application/json',
              HttpHeaders.acceptHeader: 'application/json',
            },
            body: payload,
          )
          .timeout(_timeout);

      print('🚨 [HTTP POST RESPONSE] STATUS CODE: ${response.statusCode}');
      print('🚨 [HTTP POST RESPONSE] BODY: ${response.body}');

      final decoded = _decodeJsonResponse(response);

      if (response.statusCode < 200 || response.statusCode >= 300) {
        throw ApiException(
          statusCode: response.statusCode,
          message: _extractErrorMessage(decoded),
        );
      }

      return decoded;
    } on ApiException {
      rethrow;
    } on SocketException {
      throw const ApiException(message: 'connection');
    } on http.ClientException {
      throw const ApiException(message: 'connection');
    } on TimeoutException {
      throw const ApiException(message: 'timeout');
    }
  }

  Future<Map<String, dynamic>> _getJson(
    String path, {
    required String accessToken,
  }) async {
    try {
      final response = await _client
          .get(
            Uri.parse('$baseUrl$path'),
            headers: {
              HttpHeaders.acceptHeader: 'application/json',
              HttpHeaders.authorizationHeader: 'Bearer $accessToken',
            },
          )
          .timeout(_timeout);

      final decoded = _decodeJsonResponse(response);

      if (response.statusCode < 200 || response.statusCode >= 300) {
        throw ApiException(
          statusCode: response.statusCode,
          message: _extractErrorMessage(decoded),
        );
      }

      return decoded;
    } on ApiException {
      rethrow;
    } on SocketException {
      throw const ApiException(message: 'connection');
    } on http.ClientException {
      throw const ApiException(message: 'connection');
    } on TimeoutException {
      throw const ApiException(message: 'timeout');
    }
  }

  Map<String, dynamic> _decodeJsonResponse(http.Response response) {
    try {
      final body = utf8.decode(response.bodyBytes);
      final decoded = jsonDecode(body);

      if (decoded is Map<String, dynamic>) {
        return decoded;
      }

      throw const ApiException(message: 'invalid_json');
    } on FormatException {
      throw ApiException(
        statusCode: response.statusCode,
        message: 'invalid_json',
      );
    }
  }

  String _extractMessage(Map<String, dynamic> json) {
    final message = json['message'];

    return message is String && message.trim().isNotEmpty
        ? message
        : 'success';
  }

  String _extractErrorMessage(Map<String, dynamic> json) {
    final error = json['error'];
    if (error is String && error.trim().isNotEmpty) {
      return error;
    }

    final message = json['message'];
    if (message is String && message.trim().isNotEmpty) {
      return message;
    }

    return 'error';
  }
}
