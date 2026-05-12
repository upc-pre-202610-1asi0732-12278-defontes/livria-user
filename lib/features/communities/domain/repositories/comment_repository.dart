// features/communities/domain/repositories/comment_repository.dart
import '../entities/comment.dart';

abstract class CommentRepository {
  Future<List<Comment>> fetchCommentsByPostId(int postId);
  Future<Comment> createComment({
    required int postId,
    required int userId,
    required String content,
  });
}