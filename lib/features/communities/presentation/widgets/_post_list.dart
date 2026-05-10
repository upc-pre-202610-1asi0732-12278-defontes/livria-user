import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:livria_user/common/theme/app_colors.dart';
import '../../domain/entities/post.dart';
import '../providers/post_provider.dart'; // Ajusta la ruta a tu PostProvider
import '../../../profile/presentation/providers/profile_provider.dart'; // Ajusta la ruta a tu ProfileProvider
import 'post_card.dart';

class PostList extends StatelessWidget {
  final int communityId;

  const PostList({super.key, required this.communityId});

  @override
  Widget build(BuildContext context) {
    // 1. Obtenemos los posts del PostProvider
    final postProvider = context.watch<PostProvider>();
    final posts = postProvider.posts;

    // Si la lista está vacía y no está cargando, disparamos la carga
    if (postProvider.posts.isEmpty && !postProvider.isLoading && postProvider.errorMessage == null) {
      Future.microtask(() =>
          context.read<PostProvider>().loadPosts(communityId)
      );
    }

    // 2. Obtenemos los datos del usuario actual del ProfileProvider
    final profileProvider = context.watch<ProfileProvider>();
    final currentUser = profileProvider.user;

    // Extraemos lo que necesitamos para comparar
    final String? currentUsername = currentUser?.username;
    final String? currentUserIconUrl = currentUser?.icon;

    if (postProvider.isLoading) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(32.0),
          child: CircularProgressIndicator(color: AppColors.primaryOrange),
        ),
      );
    }

    if (posts.isEmpty) {
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16.0),
        child: Center(
          child: Text(
            'There are no posts in this community',
            style: Theme.of(context).textTheme.bodyMedium!.copyWith(
                color: AppColors.black.withOpacity(0.5)
            ),
          ),
        ),
      );
    }

    const String defaultIcon = 'https://cdn-icons-png.flaticon.com/512/3447/3447354.png';

    // Nota: Si el PostProvider ya ordena los posts, quizás no necesites el .reversed
    final List<Post> displayPosts = posts;

    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: displayPosts.length,
      itemBuilder: (context, index) {
        final post = displayPosts[index];

        // Ahora estas variables ya existen arriba
        final bool isOwner = (currentUsername != null && post.username == currentUsername);

        final String iconToUse = isOwner
            ? (currentUserIconUrl != null && currentUserIconUrl.isNotEmpty ? currentUserIconUrl : defaultIcon)
            : defaultIcon;

        return PostCard(
          post: post,
          userIconUrl: iconToUse,
          isOwner: isOwner,
          onEdit: () {
            _showEditDialog(context, post);
          },
          onDelete: () {
            _confirmDelete(context, post.id);
          },
        );
      },
    );
  }

  // --- Helpers para acciones ---

  void _confirmDelete(BuildContext context, int postId) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text("Delete Post"),
        content: const Text("Are you sure you want to delete this post?"),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text("Cancel")),
          TextButton(
              onPressed: () {
                context.read<PostProvider>().deletePost(postId);
                Navigator.pop(ctx);
              },
              child: const Text("Delete", style: TextStyle(color: Colors.red))
          ),
        ],
      ),
    );
  }

  void _showEditDialog(BuildContext context, Post post) {
    // Aquí podrías abrir un bottom sheet o dialog con un TextField
    // llamando a context.read<PostProvider>().editPost(...)
    print("Opening edit for: ${post.content}");
  }
}