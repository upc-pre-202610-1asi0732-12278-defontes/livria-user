import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import 'package:livria_user/common/theme/app_colors.dart';
import '../../domain/entities/post.dart';
import '../providers/post_provider.dart';
import '../../../profile/presentation/providers/profile_provider.dart';
import 'post_card.dart';

class PostList extends StatefulWidget {
  final int communityId;
  final int? currentUserId;

  const PostList({super.key, required this.communityId, this.currentUserId});

  @override
  State<PostList> createState() => _PostListState();
}

class _PostListState extends State<PostList> {

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<PostProvider>().loadPosts(widget.communityId);
      final profileProvider = context.read<ProfileProvider>();
      if (profileProvider.user == null) {
        profileProvider.loadData();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    // Escuchamos los cambios
    final postProvider = context.watch<PostProvider>();
    final posts = postProvider.posts;

    final profileProvider = context.watch<ProfileProvider>();
    final currentUser = profileProvider.user;

    final String? currentUsername = currentUser?.username;
    final String? currentUserIconUrl = currentUser?.icon;

    // 1. Estado de Carga
    if (postProvider.isLoading && posts.isEmpty) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(32.0),
          child: CircularProgressIndicator(color: AppColors.primaryOrange),
        ),
      );
    }

    // 2. Estado de Error
    if (postProvider.errorMessage != null && posts.isEmpty) {
      return Center(child: Text("Error: ${postProvider.errorMessage}"));
    }

    // 3. Lista Vacía
    if (posts.isEmpty) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 40, horizontal: 16.0),
        child: Center(
          child: Text(
            'There are no posts in this community',
            style: Theme.of(context).textTheme.bodyMedium!.copyWith(
                color: AppColors.black.
                withOpacity(0.5)
            ),
          ),
        ),
      );
    }

    const String defaultIcon = 'https://cdn-icons-png.flaticon.com/512/3447/3447354.png';

    List<Post> display = posts.reversed.toList();

    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: display.length,
      itemBuilder: (context, index) {
        final post = display[index];
        final bool isOwner = widget.currentUserId != null && post.userId == widget.currentUserId;

        final String iconToUse = isOwner
            ? (currentUserIconUrl != null && currentUserIconUrl.isNotEmpty ? currentUserIconUrl : defaultIcon)
            : defaultIcon;

        return PostCard(
          post: post,
          userIconUrl: iconToUse,
          isOwner: isOwner,
          onEdit: () => _showEditDialog(context, post),
          onDelete: () => _confirmDelete(context, post.id),
        );
      },
    );
  }

  // --- Helpers para acciones ---
  void _confirmDelete(BuildContext context, int postId) {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text("Delete Post"),
        content: const Text("Are you sure?"),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text("Cancel"),
          ),
          TextButton(
            onPressed: () async {
              final success = await context.read<PostProvider>().deletePost(postId);

              if (Navigator.canPop(dialogContext)) {
                Navigator.pop(dialogContext);
              }

              if (!success && context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text("Error: Could not delete post")),
                );
              }
            },
            child: const Text("Delete", style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  void _showEditDialog(BuildContext context, Post post) {
    final controller = TextEditingController(text: post.content);
    File? selectedImage;
    String? currentImg = post.img;

    showDialog(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text(
              "Edit Post",
            style: TextStyle(color: AppColors.darkBlue, fontSize: 24, fontWeight: FontWeight.bold),
          ),
          content: SizedBox(
            width: double.maxFinite,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  TextField(
                    controller: controller,
                    maxLines: 3,
                    decoration: const InputDecoration(hintText: "Write something..."),
                  ),
                  const SizedBox(height: 12),

                  // Preview de imagen actual o seleccionada
                  if (selectedImage != null)
                    Stack(
                      children: [
                        ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: Image.file(
                            selectedImage!,
                            height: 120,
                            width: double.infinity,
                            fit: BoxFit.cover,
                          ),
                        ),
                        Positioned(
                          top: 4, right: 4,
                          child: GestureDetector(
                            onTap: () => setDialogState(() {
                              selectedImage = null;
                              currentImg = "";
                            }),
                            child: const CircleAvatar(
                              radius: 12,
                              backgroundColor: Colors.red,
                              child: Icon(Icons.close, size: 14, color: Colors.white),
                            ),
                          ),
                        ),
                      ],
                    )
                  else if (currentImg != null && currentImg!.isNotEmpty && currentImg != "string")
                    Stack(
                      children: [
                        ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: currentImg!.startsWith('data:image') || (!currentImg!.startsWith('http') && currentImg!.length > 100)
                              ? Image.memory(
                            base64Decode(currentImg!.contains(',') ? currentImg!.split(',').last : currentImg!),
                            height: 120,
                            width: double.infinity,
                            fit: BoxFit.cover,
                          )
                              : Image.network(
                            currentImg!,
                            height: 120,
                            width: double.infinity,
                            fit: BoxFit.cover,
                          ),
                        ),
                        Positioned(
                          top: 4, right: 4,
                          child: GestureDetector(
                            onTap: () => setDialogState(() => currentImg = ""),
                            child: const CircleAvatar(
                              radius: 12,
                              backgroundColor: Colors.red,
                              child: Icon(Icons.close, size: 14, color: Colors.white),
                            ),
                          ),
                        ),
                      ],
                    ),

                  const SizedBox(height: 8),
                  TextButton.icon(
                    onPressed: () async {
                      final picker = ImagePicker();
                      final XFile? picked = await picker.pickImage(
                        source: ImageSource.gallery,
                        imageQuality: 70,
                      );
                      if (picked != null) {
                        setDialogState(() => selectedImage = File(picked.path));
                      }
                    },
                    icon: const Icon(Icons.image_outlined, color: AppColors.primaryOrange),
                    label: const Text(
                        "Change image",
                      style: TextStyle(color: AppColors.vibrantBlue, fontSize: 16),
                    ),
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text("Cancel",style: TextStyle(color: AppColors.primaryOrange, fontSize: 16)),
            ),
            TextButton(
              onPressed: () async {
                String? finalImg = currentImg;

                // Si eligió nueva imagen, conviértela a base64
                if (selectedImage != null) {
                  final bytes = await selectedImage!.readAsBytes();
                  finalImg = "data:image/jpeg;base64,${base64Encode(bytes)}";
                }

                final success = await context.read<PostProvider>().editPost(
                  post.id,
                  controller.text,
                  finalImg,
                );
                if (success && Navigator.canPop(dialogContext)) {
                  Navigator.pop(dialogContext);
                }
              },
              child: const Text("Save",style: TextStyle(color: AppColors.primaryOrange, fontSize: 16)),
            ),
          ],
        ),
      ),
    );
  }
}