import 'dart:convert';
import 'package:flutter/cupertino.dart';
import 'package:http/http.dart' as http;
import 'package:livria_user/common/config/env.dart';
import '../../../auth/infrastructure/datasource/auth_local_datasource.dart';
import '../../domain/entities/post.dart';

class PostRemoteDataSource {
  static final String _base = Env.apiBase;
  static const String _postsPath = '/api/v1/posts';

  final AuthLocalDataSource _authDs;
  final http.Client _client;

  PostRemoteDataSource({http.Client? client, AuthLocalDataSource? authDs})
      : _client = client ?? http.Client(),
        _authDs = authDs ?? AuthLocalDataSource();

  // --- Lógica Auxiliar para Headers Autenticados ---
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
  // --------------------------------------------------

  // posts

  /// Obtiene los posts por comunidad, los parsea, y los ordena por fecha de creación (más recientes primero).
  Future<List<Post>> fetchPostsByCommunityId(int communityId, int offset, int limit) async {
    final uri = Uri.parse('$_base$_postsPath/community/$communityId?offset=$offset&limit=$limit');
    final headers = await _getAuthenticatedHeaders();

    final response = await _client.get(
      uri,
      headers: headers,
    );

    if (response.statusCode == 200) {
      final List<dynamic> jsonList = json.decode(response.body);
      final List<Post> posts = jsonList.map((json) => Post.fromJson(json)).toList();

      // Implementación del orden: Más recientes primero (descendente)
      posts.sort((a, b) {
        try {
          // Asumimos que a.createdAt y b.createdAt son String (viniendo de la API)
          final dateA = DateTime.parse(a.createdAt as String);
          final dateB = DateTime.parse(b.createdAt as String);

          return dateB.compareTo(dateA);
        } catch (e) {
          // No cambiar el orden si el parseo falla
          return 0;
        }
      });

      return posts; // Ahora devuelve List<Post> ordenado
    } else {
      throw Exception('Failed to load posts. Status: ${response.statusCode}. Body: ${response.body}');
    }
  }

  Future<http.Response> fetchPostById(int id) async {
    final uri = Uri.parse('$_base$_postsPath/$id');
    final headers = await _getAuthenticatedHeaders();

    return _client.get(
      uri,
      headers: headers,
    );
  }

  /// Crea un nuevo post enviando la solicitud POST con el username.
  Future<http.Response> createPost({
    required int communityId,
    required int userId,
    required String username,
    required String content,
    String? img,
  }) async {
    final uri = Uri.parse('$_base$_postsPath/communities/$communityId');
    final headers = await _getAuthenticatedHeaders();

    final body = jsonEncode({
      "userId": userId,
      "username": username,
      "content": content,
      "img": img ?? "",
    });

    return _client.post(
      uri,
      headers: headers,
      body: body,
    );
  }

  // Borra un post
  // Borra un post
  Future<void> deletePost(int postId) async {
    final uri = Uri.parse('$_base$_postsPath/$postId');
    final headers = await _getAuthenticatedHeaders();

    final userId = await _authDs.getUserId();

    final body = jsonEncode({
      "resource": "post",
      "userId": userId,
      "id": postId
    });

    debugPrint("🔴 [POST DELETE] Requesting: $uri with body: $body");

    final request = http.Request('DELETE', uri)
      ..headers.addAll(headers)
      ..body = body;

    final streamedResponse = await _client.send(request);
    final response = await http.Response.fromStream(streamedResponse);

    debugPrint("🟣 [POST DELETE] Response: ${response.statusCode}");
    debugPrint("📦 [BODY]: ${response.body}");

    if (response.statusCode != 200 && response.statusCode != 204) {
      throw Exception('Failed to delete post: ${response.body}');
    }
  }

  // Editar post
  Future<Post> updatePost(int postId, String content, String? img) async {
    final uri = Uri.parse('$_base$_postsPath/$postId');
    final headers = await _getAuthenticatedHeaders();
    final userId = await _authDs.getUserId();

    final body = jsonEncode({
      "userId": userId,
      "content": content,
      "img": img ?? "",
    });

    final response = await _client.put(uri, headers: headers, body: body);

    if (response.statusCode == 200) {
      return Post.fromJson(json.decode(response.body));
    } else {
      throw Exception('Fallo al editar post: ${response.body}');
    }
  }

  // Obtener conteo de likes/dislikes
  Future<Map<String, int>> fetchReactionCounts(int postId) async {
    final uri = Uri.parse('$_base$_postsPath/$postId/reactions/counts');
    final headers = await _getAuthenticatedHeaders();
    final response = await _client.get(uri, headers: headers);

    if (response.statusCode == 200) {
      final json = jsonDecode(response.body);
      return {
        'likes': json['likes'] ?? 0,
        'dislikes': json['dislikes'] ?? 0,
      };
    } else {
      throw Exception('Failed to fetch reaction counts: ${response.statusCode}');
    }
  }

  // Verificar reacción del usuario (devuelve 1=like, 2=dislike, 0=ninguna)
  Future<int> fetchUserReactionStatus(int postId, int userId) async {
    final uri = Uri.parse('$_base$_postsPath/$postId/user/$userId/reaction-status');
    final headers = await _getAuthenticatedHeaders();
    final response = await _client.get(uri, headers: headers);

    debugPrint('🟡 reactionStatus → status: ${response.statusCode}');
    debugPrint('🟡 reactionStatus → body: ${response.body}');

    if (response.statusCode == 200) {
      final json = jsonDecode(response.body);
      return json['status'] ?? 0;
    } else if (response.statusCode == 404) {
      return 0;
    } else {
      throw Exception('Failed to fetch reaction status: ${response.statusCode}');
    }
  }

  // Registrar, actualizar o eliminar reacción (type: 1=like, 2=dislike)
  Future<void> reactToPost(int postId, int userId, int type) async {
    final uri = Uri.parse('$_base$_postsPath/$postId/reactions');
    final headers = await _getAuthenticatedHeaders();
    final body = jsonEncode({'userId': userId, 'type': type});

    debugPrint('🔵 reactToPost → uri: $uri');
    debugPrint('🔵 reactToPost → body: $body');

    final response = await _client.post(uri, headers: headers, body: body);

    debugPrint('🔵 reactToPost → status: ${response.statusCode}');
    debugPrint('🔵 reactToPost → response: ${response.body}');

    if (response.statusCode != 200 && response.statusCode != 201 && response.statusCode != 204) {
      throw Exception('Failed to react to post: ${response.body}');
    }
  }

  Future<List<int>> fetchLikedPostIds(int userId) async {
    final uri = Uri.parse('$_base$_postsPath/user/$userId/liked');
    final headers = await _getAuthenticatedHeaders();
    final response = await _client.get(uri, headers: headers);

    if (response.statusCode == 200) {
      final List<dynamic> jsonList = jsonDecode(response.body);
      return jsonList.map((p) => p['id'] as int).toList();
    } else if (response.statusCode == 404) {
      return [];
    } else {
      throw Exception('Failed to fetch liked posts: ${response.statusCode}');
    }
  }

  Future<List<int>> fetchDislikedPostIds(int userId) async {
    final uri = Uri.parse('$_base$_postsPath/user/$userId/disliked');
    final headers = await _getAuthenticatedHeaders();
    final response = await _client.get(uri, headers: headers);

    if (response.statusCode == 200) {
      final List<dynamic> jsonList = jsonDecode(response.body);
      return jsonList.map((p) => p['id'] as int).toList();
    } else if (response.statusCode == 404) {
      return [];
    } else {
      throw Exception('Failed to fetch disliked posts: ${response.statusCode}');
    }
  }
}