
import '../../domain/entities/comment.dart';
import '../../domain/repositories/comment_repository.dart';
import '../datasource/comment_remote_datasource.dart';

class CommentRepositoryImpl implements CommentRepository {
  final CommentRemoteDataSource _dataSource;

  const CommentRepositoryImpl(this._dataSource);

  @override
  Future<List<Comment>> fetchCommentsByPostId(int postId) =>
      _dataSource.fetchCommentsByPostId(postId);

  @override
  Future<Comment> createComment({
    required int postId,
    required int userId,
    required String content,
  }) => _dataSource.createComment(
    postId: postId,
    userId: userId,
    content: content,
  );
}