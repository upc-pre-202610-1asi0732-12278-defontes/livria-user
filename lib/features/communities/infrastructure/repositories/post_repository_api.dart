import 'dart:convert';
import 'package:http/http.dart' as http;
import '../../domain/entities/post.dart';
import '../../domain/repositories/post_repository.dart';
import '../../infrastructure/datasource/post_remote_datasource.dart';

class PostRepositoryApi implements PostRepository {
  final PostRemoteDataSource _dataSource;

  const PostRepositoryApi({required PostRemoteDataSource dataSource})
      : _dataSource = dataSource;

  Post _mapPost(String responseBody) {
    try {
      final Map<String, dynamic> jsonMap = json.decode(responseBody);
      return Post.fromJson(jsonMap);
    } catch (e) {
      throw Exception('Failed to parse post JSON: $e');
    }
  }

  // Se mantiene si se usa en otros métodos, aunque no es necesaria para fetchPostsByCommunityId
  List<Post> _mapPostList(String responseBody) {
    try {
      final List<dynamic> jsonList = json.decode(responseBody);
      return jsonList.map((json) => Post.fromJson(json)).toList();
    } catch (e) {
      throw Exception('Failed to parse post list JSON: $e');
    }
  }

  // -----------------------------------------------------------------------

  @override
  Future<Post> fetchPostById(int id) async {
    final http.Response response = await _dataSource.fetchPostById(id);

    if (response.statusCode == 200) {
      return _mapPost(response.body);
    } else {
      throw Exception('Failed to load post $id. Status: ${response.statusCode}');
    }
  }

  @override
  Future<List<Post>> fetchPostsByCommunityId(int communityId, int offset, int limit) async {
    final List<Post> posts = await _dataSource.fetchPostsByCommunityId(communityId, offset, limit);

    return posts;
  }

  @override
  Future<Post> createPost({
    required int communityId,
    required int userId,
    required String username,
    required String content,
    String? img,
  }) async {
    // 1. Llamar al DataSource
    final http.Response response = await _dataSource.createPost(
      communityId: communityId,
      userId: userId,
      username: username,
      content: content,
      img: img,
    );

    // 2. Manejar la respuesta HTTP. 201 Created es lo estándar para POST.
    if (response.statusCode == 201 || response.statusCode == 200) {
      return _mapPost(response.body);
    } else {
      throw Exception('Failed to create post. Status: ${response.statusCode}, Body: ${response.body}');
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