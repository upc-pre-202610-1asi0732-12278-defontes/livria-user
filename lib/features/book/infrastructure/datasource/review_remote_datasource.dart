import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:livria_user/common/config/env.dart';

import '../../../auth/infrastructure/datasource/auth_local_datasource.dart';

class ReviewRemoteDataSource {
  static final String _base = Env.apiBase;
  static const String _reviewsPath = '/api/v1/reviews';

  final http.Client _client;
  // Añadir la dependencia al local data source para obtener el token
  final AuthLocalDataSource _authDs;

  ReviewRemoteDataSource({http.Client? client, AuthLocalDataSource? authDs})
      : _client = client ?? http.Client(),
        _authDs = authDs ?? AuthLocalDataSource();

  Future<http.Response> getAllReviews() {
    final uri = Uri.parse('$_base$_reviewsPath');
    return _client.get(uri);
  }

  Future<http.Response> getBookReviews(int id) async {
    final uri = Uri.parse('$_base$_reviewsPath/book/$id');
    final token = await _authDs.getToken();

    if (token == null || token.isEmpty) {
      throw Exception('Error 401: Token de autorización no encontrado.');
    }

    return _client.get(
      uri,
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );
  }

  Future<http.Response> postReview({
    required int bookId,
    required String content,
    required int stars,
  }) async {
    final uri = Uri.parse('$_base$_reviewsPath');

    // Obtener Token y UserId
    final token = await _authDs.getToken();
    final userId = await _authDs.getUserId();

    if (token == null || token.isEmpty || userId == null) {
      throw Exception('Error 401: El usuario debe estar loggeado para publicar una reseña.');
    }

    // Cuerpo de la solicitud
    final body = json.encode({
      'bookId': bookId,
      'userClientId': userId,
      'content': content,
      'stars': stars,
    });

    return _client.post(
      uri,
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: body,
    );
  }

}