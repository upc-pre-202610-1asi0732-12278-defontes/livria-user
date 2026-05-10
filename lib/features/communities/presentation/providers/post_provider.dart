import 'package:flutter/material.dart';
import '../../domain/entities/comment.dart';
import '../../domain/entities/post.dart';
import '../../domain/repositories/comment_repository.dart';
import '../../domain/repositories/post_repository.dart';

class PostProvider extends ChangeNotifier {
  final PostRepository postRepository;
  final CommentRepository commentRepository;

  PostProvider({
    required this.postRepository,
    required this.commentRepository,
  });

  // ESTADO
  List<Post> _posts = [];
  bool _isLoading = false;
  String? _errorMessage;

  // GETTERS
  List<Post> get posts => _posts;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  // --- MÉTODOS ---

  // Cargar posts de una comunidad
  Future<void> loadPosts(int communityId) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      // Usamos offset 0 y limit 50 por defecto, ajusta según necesites
      _posts = await postRepository.fetchPostsByCommunityId(communityId, 0, 50);
    } catch (e) {
      _errorMessage = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  //Cargar reacciones
  Future<void> loadReactions(int postId, int userId) async {
    try {
      final results = await Future.wait([
        postRepository.fetchReactionCounts(postId),
        postRepository.fetchUserReactionStatus(postId, userId),
      ]);
      final counts = results[0] as Map<String, int>;
      final status = results[1] as int;

      _likesCount[postId] = counts['likes'] ?? 0;
      _dislikesCount[postId] = counts['dislikes'] ?? 0;
      _userReaction[postId] = status;
      notifyListeners();
    } catch (e) {
      debugPrint('Error loading reactions: $e');
    }
  }

  // Crear un nuevo post
  Future<bool> addPost({
    required int communityId,
    required int userId,
    required String username,
    required String content,
    String? img,
  }) async {
    try {
      final newPost = await postRepository.createPost(
        communityId: communityId,
        userId: userId,
        username: username,
        content: content,
        img: img,
      );

      _posts.insert(0, newPost);

      notifyListeners();
      return true;
    } catch (e) {
      debugPrint("❌ Error al añadir post en Provider: $e");
      return false;
    }
  }

  // Borrar post
  Future<bool> deletePost(int postId) async {
    debugPrint("🟢 Iniciando borrado del post: $postId");
    try {
      await postRepository.deletePost(postId);
      debugPrint("✅ Borrado en servidor exitoso");

      _posts.removeWhere((p) => p.id == postId);
      notifyListeners();
      return true;
    } catch (e) {
      debugPrint("❌ Error en PostProvider.deletePost: $e");
      return false;
    }
  }

  // Editar post
  Future<bool> editPost(int postId, String content, String? img) async {
    try {
      final updatedPost = await postRepository.updatePost(postId, content, img);

      // Reemplazo reactivo en local
      final index = _posts.indexWhere((p) => p.id == postId);
      if (index != -1) {
        _posts[index] = updatedPost;
        notifyListeners();
      }
      return true;
    } catch (e) {
      debugPrint("Error editando post: $e");
      return false;
    }
  }

  // ---------- COMMENTS ----------------------
  // ESTADO de comentarios
  final Map<int, List<Comment>> _commentsByPost = {};
  final Map<int, bool> _loadingCommentsByPost = {};

  // GETTERS
  List<Comment> commentsForPost(int postId) => _commentsByPost[postId] ?? [];
  bool isLoadingCommentsForPost(int postId) => _loadingCommentsByPost[postId] ?? false;

  Future<void> loadComments(int postId) async {
    _loadingCommentsByPost[postId] = true;
    notifyListeners();

    try {
      _commentsByPost[postId] = await commentRepository.fetchCommentsByPostId(postId);
    } catch (e) {
      debugPrint('Error cargando comments: $e');
    } finally {
      _loadingCommentsByPost[postId] = false;
      notifyListeners();
    }
  }

  Future<bool> addComment({
    required int postId,
    required int userId,
    required String content,
  }) async {
    try {
      final newComment = await commentRepository.createComment(
        postId: postId,
        userId: userId,
        content: content,
      );
      _commentsByPost[postId] = [newComment, ...(_commentsByPost[postId] ?? [])];
      notifyListeners();
      return true;
    } catch (e) {
      debugPrint('Error añadiendo comment: $e');
      return false;
    }
  }

  // ---------- LIKES Y DISLIKES ----------------------
  // ESTADO de reacciones
  final Map<int, int> _likesCount = {};
  final Map<int, int> _dislikesCount = {};
  final Map<int, int> _userReaction = {}; // 0=none, 1=like, 2=dislike

  // GETTERS
  int likesForPost(int postId) => _likesCount[postId] ?? 0;
  int dislikesForPost(int postId) => _dislikesCount[postId] ?? 0;
  int userReactionForPost(int postId) => _userReaction[postId] ?? 0;


  Future<void> reactToPost(int postId, int userId, int type) async {
    try {
      await postRepository.reactToPost(postId, userId, type);
      debugPrint('✅ reactToPost OK');

      final newStatus = await postRepository.fetchUserReactionStatus(postId, userId);
      debugPrint('✅ fetchUserReactionStatus: $newStatus');

      final counts = await postRepository.fetchReactionCounts(postId);
      debugPrint('✅ fetchReactionCounts: $counts');

      _userReaction[postId] = newStatus;
      _likesCount[postId] = counts['likes'] ?? 0;
      _dislikesCount[postId] = counts['dislikes'] ?? 0;
      notifyListeners();
    } catch (e) {
      debugPrint('❌ Error reacting to post: $e');
    }
  }

  Future<void> loadUserReactions(int userId) async {
    try {
      final results = await Future.wait([
        postRepository.fetchLikedPostIds(userId),
        postRepository.fetchDislikedPostIds(userId),
      ]);
      final likedIds = results[0] as List<int>;
      final dislikedIds = results[1] as List<int>;

      for (final id in likedIds) {
        _userReaction[id] = 1;
      }
      for (final id in dislikedIds) {
        _userReaction[id] = 2;
      }
      notifyListeners();
    } catch (e) {
      debugPrint('Error loading user reactions: $e');
    }
  }
}