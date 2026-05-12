import 'dart:convert';
import 'package:http/http.dart' as http;
import '../../domain/entities/post.dart';
import '../../domain/repositories/post_repository.dart';
import '../../infrastructure/datasource/post_remote_datasource.dart';

class PostRepositoryImpl implements PostRepository {
  final PostRemoteDataSource _dataSource;

  // Constructor posicional
  const PostRepositoryImpl(this._dataSource);

  // Mapeo para un solo post (usado por fetchPostById y createPost)
  Post _mapPost(String responseBody) {
    try {
      final Map<String, dynamic> jsonMap = json.decode(responseBody);
      return Post.fromJson(jsonMap);
    } catch (e) {
      throw Exception('Fallo al parsear JSON de Post: $e');
    }
  }

  // Mapeo para lista de posts (Solo se usará si el DataSource devuelve Response)
  List<Post> _mapPostList(String responseBody) {
    try {
      final List<dynamic> jsonList = json.decode(responseBody);
      return jsonList.map((jsonItem) =>
          Post.fromJson(jsonItem as Map<String, dynamic>)).toList();
    } catch (e) {
      throw Exception('Fallo al parsear JSON de lista de Posts: $e');
    }
  }

  // -----------------------------------------------------------------------

  @override
  Future<List<Post>> fetchPostsByCommunityId(int communityId, int offset, int limit) async {
    final List<Post> posts = await _dataSource.fetchPostsByCommunityId(communityId, offset, limit);
    return posts;
  }

  @override
  Future<Post> fetchPostById(int id) async {
    // Este método sigue usando el patrón antiguo (DataSource devuelve http.Response)
    final http.Response response = await _dataSource.fetchPostById(id);

    if (response.statusCode == 200) {
      return _mapPost(response.body);
    } else {
      throw Exception('HTTP ${response.statusCode}: Fallo al cargar el post con ID $id.');
    }
  }

  @override
  Future<Post> createPost({
    required int communityId,
    required int userId,
    required String username,
    required String content,
    String? img,
  }) async {
    final http.Response response = await _dataSource.createPost(
      communityId: communityId,
      userId: userId,
      username: username,
      content: content,
      img: img,
    );

    if (response.statusCode == 201 || response.statusCode == 200) {
      return _mapPost(response.body);
    } else {
      throw Exception('HTTP ${response.statusCode}: Fallo al crear el post. Cuerpo: ${response.body}');
    }
  }

  @override
  Future<void> deletePost(int postId) async {
    await _dataSource.deletePost(postId);
  }

  @override
  Future<Post> updatePost(int postId, String content, String? img) async {
    final updatedPost = await _dataSource.updatePost(postId, content, img);
    return updatedPost;
  }

  @override
  Future<Map<String, int>> fetchReactionCounts(int postId) =>
      _dataSource.fetchReactionCounts(postId);

  @override
  Future<int> fetchUserReactionStatus(int postId, int userId) =>
      _dataSource.fetchUserReactionStatus(postId, userId);

  @override
  Future<void> reactToPost(int postId, int userId, int type) =>
      _dataSource.reactToPost(postId, userId, type);

  @override
  Future<List<int>> fetchLikedPostIds(int userId) =>
      _dataSource.fetchLikedPostIds(userId);

  @override
  Future<List<int>> fetchDislikedPostIds(int userId) =>
      _dataSource.fetchDislikedPostIds(userId);
}