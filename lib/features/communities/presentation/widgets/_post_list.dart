import 'package:flutter/material.dart';
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
        );
      },
    );
  }
}