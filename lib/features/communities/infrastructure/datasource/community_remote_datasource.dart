import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:livria_user/common/config/env.dart';
import '../../../auth/infrastructure/datasource/auth_local_datasource.dart';

class CommunityRemoteDataSource {
  static const String _base = Env.apiBase;
  static const String _communitiesPath = '/api/v1/communities';
  static const String _userComPath = '/api/v1/users';

  final AuthLocalDataSource _authDs;
  final http.Client _client;

  CommunityRemoteDataSource({http.Client? client, AuthLocalDataSource? authDs})
      : _client = client ?? http.Client(),
        _authDs = authDs ?? AuthLocalDataSource();

  Future<Map<String, String>> _getAuthenticatedHeaders() async {
    final token = await _authDs.getToken();

    if (token == null || token.isEmpty) {
      // Usamos una excepción estándar que puede ser capturada por la capa de presentación
      throw Exception('Error 401: Token de autorización no encontrado. El usuario debe iniciar sesión.');
    }

    return {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer $token',
    };
  }
  // --------------------------------------------------

  // communities
  Future<http.Response> fetchCommunityList(int offset, int limit) async {
    final uri = Uri.parse('$_base$_communitiesPath?offset=$offset&limit=$limit');
    final headers = await _getAuthenticatedHeaders(); // Obtenemos el token

    return _client.get(
      uri,
      headers: headers,
    );
  }

  Future<http.Response> fetchCommunitiesByUser({required int userId}) async {
    final uri = Uri.parse('$_base$_userComPath/$userId/activity/owned-communities');
    final headers = await _getAuthenticatedHeaders();

    return _client.get(
      uri,
      headers: headers,
    );
  }

  Future<http.Response> fetchCommunityById(int id) async {
    final uri = Uri.parse('$_base$_communitiesPath/$id');
    final headers = await _getAuthenticatedHeaders();

    return _client.get(
      uri,
      headers: headers,
    );
  }

  /// Envía una solicitud POST para crear una nueva comunidad.
  Future<http.Response> createCommunity(Map<String, dynamic> body) async {
    final uri = Uri.parse('$_base$_communitiesPath');
    final headers = await _getAuthenticatedHeaders();

    return _client.post(
      uri,
      headers: headers,
      body: jsonEncode(body),
    );
  }

  /// Envía una solicitud POST para que un usuario se una a una comunidad.
  /// URL: /api/v1/communities/join
  Future<http.Response> joinCommunity(Map<String, dynamic> body) async {
    final uri = Uri.parse('$_base$_communitiesPath/join');
    final headers = await _getAuthenticatedHeaders();

    return _client.post(
      uri,
      headers: headers,
      body: jsonEncode(body), // { "userClientId": 0, "communityId": 0}
    );
  }

  /// Envía una solicitud DELETE para que un usuario salga de una comunidad.
  /// URL: /api/v1/communities/{communityId}/members/{userId}
  Future<http.Response> leaveCommunity({
    required int communityId,
    required int userId,
  }) async {
    final uri = Uri.parse('$_base$_communitiesPath/$communityId/members/$userId');
    final headers = await _getAuthenticatedHeaders();

    return _client.delete(
      uri,
      headers: headers,
    );
  }

  /// Envía una solicitud GET para verificar si un usuario es miembro de una comunidad.
  /// URL: /api/v1/communities/{communityId}/members/{userId}/is-member
  Future<http.Response> checkUserJoined({
    required int communityId,
    required int userId,
  }) async {
    final uri = Uri.parse('$_base$_communitiesPath/$communityId/members/$userId/is-member');
    final headers = await _getAuthenticatedHeaders();

    return _client.get(
      uri,
      headers: headers,
    );
  }
}