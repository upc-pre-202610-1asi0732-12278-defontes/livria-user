import '../entities/post.dart';

abstract class PostRepository {
  /// Obtiene una lista de posts por ID de comunidad con paginación.
  Future<List<Post>> fetchPostsByCommunityId(int communityId, int offset, int limit);

  /// Obtiene un post individual por su ID.
  Future<Post> fetchPostById(int id);

  /// Crea un nuevo post en una comunidad.
  Future<Post> createPost({
    required int communityId,
    required int userId,
    required String username,
    required String content,
    String? img,
  });

  Future<void> deletePost(int postId);
  Future<Post> updatePost(int postId, String content, String? img);

  Future<Map<String, int>> fetchReactionCounts(int postId);
  Future<int> fetchUserReactionStatus(int postId, int userId);
  Future<void> reactToPost(int postId, int userId, int type);

  Future<List<int>> fetchLikedPostIds(int userId);
  Future<List<int>> fetchDislikedPostIds(int userId);
}