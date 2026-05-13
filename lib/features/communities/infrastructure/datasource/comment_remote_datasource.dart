// features/communities/infrastructure/datasource/comment_remote_datasource.dart
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:livria_user/common/config/env.dart';
import '../../../auth/infrastructure/datasource/auth_local_datasource.dart';
import '../../domain/entities/comment.dart';

class CommentRemoteDataSource {
  static final String _base = Env.apiBase;
  static const String _commentsPath = '/api/v1/comments';
  static const String _postsPath = '/api/v1/posts';

  final AuthLocalDataSource _authDs;
  final http.Client _client;

  CommentRemoteDataSource({http.Client? client, AuthLocalDataSource? authDs})
      : _client = client ?? http.Client(),
        _authDs = authDs ?? AuthLocalDataSource();

  Future<Map<String, String>> _getAuthenticatedHeaders() async {
    final token = await _authDs.getToken();
    if (token == null || token.isEmpty) {
      throw Exception('Token no encontrado.');
    }
    return {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer $token',
    };
  }

  Future<List<Comment>> fetchCommentsByPostId(int postId) async {
    final uri = Uri.parse('$_base$_postsPath/$postId/comments');
    final headers = await _getAuthenticatedHeaders();
    final response = await _client.get(uri, headers: headers);

    if (response.statusCode == 200) {
      final List<dynamic> jsonList = json.decode(response.body);
      final comments = jsonList.map((j) => Comment.fromJson(j)).toList();
      comments.sort((a, b) {
        try {
          return DateTime.parse(b.createdAt as String)
              .compareTo(DateTime.parse(a.createdAt as String));
        } catch (_) { return 0; }
      });
      return comments;
    } else {
      throw Exception('Failed to load comments: ${response.statusCode}');
    }
  }

  Future<Comment> createComment({
    required int postId,
    required int userId,
    required String content,
  }) async {
    final uri = Uri.parse('$_base$_commentsPath');
    final headers = await _getAuthenticatedHeaders();
    final body = jsonEncode({
      "postId": postId,
      "userId": userId,
      "content": content,
    });

    final response = await _client.post(uri, headers: headers, body: body);

    if (response.statusCode == 200 || response.statusCode == 201) {
      return Comment.fromJson(json.decode(response.body));
    } else {
      throw Exception('Failed to create comment: ${response.body}');
    }
  }
}