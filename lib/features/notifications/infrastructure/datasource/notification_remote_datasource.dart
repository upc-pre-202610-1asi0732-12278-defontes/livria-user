import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:livria_user/common/config/env.dart';
import 'package:livria_user/features/auth/infrastructure/datasource/auth_local_datasource.dart';

class NotificationRemoteDataSource {
  static final String _base = Env.apiBase;
  static const String _notificationsPath = '/api/v1/notifications/user';
  static const String _hideAllPath = '/api/v1/notifications/hide-all';

  final http.Client _client;
  final AuthLocalDataSource _authDs;

  NotificationRemoteDataSource({http.Client? client, AuthLocalDataSource? authDs})
      : _client = client ?? http.Client(),
        _authDs = authDs ?? AuthLocalDataSource();

  Future<Map<String, String>> _getAuthenticatedHeaders() async {
    final token = await _authDs.getToken();

    if (token == null || token.isEmpty) {
      throw Exception('Error 401: Token de autorización no encontrado.');
    }

    return {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer $token',
    };
  }

  /// Obtiene todas las notificaciones del usuario.
  Future<http.Response> getAllNotifications(int userClientId) async {
    final uri = Uri.parse('$_base$_notificationsPath/$userClientId');
    final headers = await _getAuthenticatedHeaders();

    return _client.get(uri, headers: headers);
  }

  /// Oculta todas las notificaciones de la base de datos
  Future<void> hideAllNotifications(int userClientId) async {
    final headers = await _getAuthenticatedHeaders();
    final url = Uri.parse('$_base$_hideAllPath');
    final body = jsonEncode({
      "userClientId": userClientId,
    });
    final response = await _client.patch(
      url,
      headers: headers,
      body: body,
    );
  }
}