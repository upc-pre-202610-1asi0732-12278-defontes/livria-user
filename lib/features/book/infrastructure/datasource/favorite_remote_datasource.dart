import 'package:http/http.dart' as http;
import 'package:livria_user/common/config/env.dart';
import 'package:livria_user/features/auth/infrastructure/datasource/auth_local_datasource.dart';
import 'dart:convert';

class FavoriteRemoteDataSource {
  static final String _base = Env.apiBase;
  static const String _userClientsPath = '/api/v1/userclients';

  final http.Client _client;
  final AuthLocalDataSource authDs;

  FavoriteRemoteDataSource({
    http.Client? client,
    required this.authDs,
  }) : _client = client ?? http.Client();

  Future<void> postFavorite({
    required int userId,
    required int bookId,
  }) async {
    final String path = '$_userClientsPath/$userId/favorites/$bookId';
    final uri = Uri.parse('$_base$path');

    final token = await authDs.getToken();

    final response = await _client.post(
      uri,
      headers: {
        'Content-Type': 'application/json',
        if (token != null) 'Authorization': 'Bearer $token',
      },
    );

    if (response.statusCode == 200 || response.statusCode == 201) {
      return;
    } else {
      throw Exception('Failed to add to favorites. Status: ${response.statusCode}. Body: ${response.body}');
    }
  }

  Future<void> deleteFavorite({
    required int userId,
    required int bookId,
  }) async {
    final String path = '$_userClientsPath/$userId/favorites/$bookId';
    final uri = Uri.parse('$_base$path');

    final token = await authDs.getToken();

    final response = await _client.delete(
      uri,
      headers: {
        'Content-Type': 'application/json',
        if (token != null) 'Authorization': 'Bearer $token',
      },
    );

    if (response.statusCode == 200 || response.statusCode == 204) {
      return;
    } else {
      throw Exception('Failed to remove favorite. Status: ${response.statusCode}');
    }
  }

  Future<bool> getFavoriteStatus({
    required int userId,
    required int bookId,
  }) async {
    final String path = '$_userClientsPath/$userId/favorites';
    final uri = Uri.parse('$_base$path');

    final token = await authDs.getToken();

    final response = await _client.get(
      uri,
      headers: {
        'Content-Type': 'application/json',
        if (token != null) 'Authorization': 'Bearer $token',
      },
    );

    if (response.statusCode == 200) {
      final List<dynamic> favoritesJson = json.decode(response.body);

      final bool isFavorite = favoritesJson.any((fav) => fav['id'] == bookId);

      return isFavorite;
    } else {
      throw Exception('Failed to load favorites list. Status: ${response.statusCode}');
    }
  }
}