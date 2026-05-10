import 'package:flutter/material.dart';
import '../../domain/entities/post.dart';
import '../../domain/repositories/post_repository.dart';

class PostProvider extends ChangeNotifier {
  final PostRepository postRepository;

  PostProvider({required this.postRepository});

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
}