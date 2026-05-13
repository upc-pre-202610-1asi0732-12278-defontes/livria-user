import 'package:http/http.dart' as http;
import 'package:livria_user/common/config/env.dart';

import '../../../auth/infrastructure/datasource/auth_local_datasource.dart';

class RecommendationRemoteDataSource {
  static final String _base = Env.apiBase;
  static const String _recommendationsPath = '/api/v1/recommendations/users';

  final http.Client _client;
  final AuthLocalDataSource _authDs;

  RecommendationRemoteDataSource({http.Client? client, AuthLocalDataSource? authDs})
      : _client = client ?? http.Client(),
        _authDs = authDs ?? AuthLocalDataSource();

  Future<Map<String, String>> _getAuthenticatedHeaders() async {
    final token = await _authDs.getToken();

    if (token == null || token.isEmpty) {
      throw Exception('Error 401: Token de autorización no encontrado. El usuario debe iniciar sesión.');
    }

    return {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer $token',
    };
  }

  Future<http.Response> getRecommendedBooks(int userClientId) async {
    final uri = Uri.parse('$_base$_recommendationsPath/$userClientId');
    final headers = await _getAuthenticatedHeaders();
    return _client.get(uri, headers: headers);
  }
}