import 'package:flutter/material.dart';
import 'package:livria_user/features/communities/presentation/widgets/use_avatar.dart';
import 'package:provider/provider.dart';
import '../../../auth/infrastructure/datasource/auth_local_datasource.dart';
import '../../domain/entities/post.dart';
import 'package:livria_user/common/theme/app_colors.dart';
import 'package:intl/intl.dart';
import 'dart:convert';
import 'dart:typed_data';

import '../pages/post_detail_page.dart';
import '../providers/post_provider.dart';

class PostCard extends StatefulWidget {
  final Post post;
  final String? userIconUrl;
  final bool isOwner;

  const PostCard({
    super.key,
    required this.post,
    this.userIconUrl,
    this.isOwner = false,
  });

  @override
  State<PostCard> createState() => _PostCardState();
}

class _PostCardState extends State<PostCard> {
  String? _fetchedIconData;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final userId = await AuthLocalDataSource().getUserId();
      if (userId != null && mounted) {
        context.read<PostProvider>().loadReactions(widget.post.id, userId);
      }
    });
  }

  String _formatTimestamp(dynamic timestamp) {
    DateTime dateTime;
    try {
      if (timestamp == null) return 'Unknown date';
      String utcTimestamp = timestamp is String
          ? (timestamp.endsWith('Z') ? timestamp : '${timestamp}Z')
          : timestamp.toString();
      dateTime = DateTime.parse(utcTimestamp).toLocal();
      return DateFormat('dd/MM/yyyy \'at\' HH:mm').format(dateTime);
    } catch (e) {
      return 'Unknown date';
    }
  }

  @override
  Widget build(BuildContext context) {
    const double borderRadius = 12.0;

    // Prioridad de imagen
    String? effectiveIconData = widget.userIconUrl;
    if (effectiveIconData == null || effectiveIconData.isEmpty || effectiveIconData.contains('cdn-icons-png')) {
       effectiveIconData = _fetchedIconData;
    }

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(borderRadius)),
      margin: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 16.0),
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                UserAvatar(
                  userId: widget.post.userId,
                  radius: 18,
                  knownIconUrl: widget.userIconUrl,
                ),
                const SizedBox(width: 8),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '@${widget.post.username}',
                      style: Theme.of(context).textTheme.titleSmall!.copyWith(
                        fontWeight: FontWeight.bold,
                        color: AppColors.darkBlue,
                      ),
                    ),
                    Text(
                      _formatTimestamp(widget.post.createdAt),
                      style: Theme.of(context).textTheme.bodySmall!.copyWith(
                        color: AppColors.black.withOpacity(0.6),
                      ),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              widget.post.content,
              style: Theme.of(context).textTheme.bodyLarge!.copyWith(color: AppColors.black),
            ),
            if (widget.post.img.isNotEmpty && widget.post.img != "string") ...[
              const SizedBox(height: 12),
              ClipRRect(
                borderRadius: BorderRadius.circular(8.0),
                child: Builder(
                  builder: (context) {
                    final imageStr = widget.post.img;
                    if (imageStr.startsWith('data:image') || (imageStr.length > 100 && !imageStr.startsWith('http'))) {
                      try {
                        final base64String = imageStr.contains(',') ? imageStr.split(',').last : imageStr;
                        final Uint8List bytes = base64Decode(base64String);
                        return Image.memory(bytes, fit: BoxFit.cover, width: double.infinity);
                      } catch (e) {
                        return const SizedBox();
                      }
                    } else {
                      return Image.network(
                        imageStr,
                        fit: BoxFit.cover,
                        width: double.infinity,
                        errorBuilder: (_, __, ___) => Container(
                          padding: const EdgeInsets.all(16),
                          color: AppColors.lightGrey,
                          child: const Center(child: Icon(Icons.broken_image)),
                        ),
                      );
                    }
                  }
                ),
              ),
            ],
            const SizedBox(height: 8),
            const Divider(height: 1, color: AppColors.lightGrey),
            // Reemplaza el Row de likes por este:
            Consumer<PostProvider>(
              builder: (context, provider, _) {
                final likes = provider.likesForPost(widget.post.id);
                final dislikes = provider.dislikesForPost(widget.post.id);
                final userReaction = provider.userReactionForPost(widget.post.id);

                return Row(
                  children: [
                    IconButton(
                      icon: Icon(
                        userReaction == 1 ? Icons.thumb_up_alt : Icons.thumb_up_alt_outlined,
                        size: 20,
                        color: userReaction == 1 ? AppColors.primaryOrange : AppColors.primaryOrange,
                      ),
                      onPressed: () async {
                        final userId = await AuthLocalDataSource().getUserId();
                        debugPrint('userReaction ANTES: ${provider.userReactionForPost(widget.post.id)}');
                        if (userId != null) {
                          await context.read<PostProvider>().reactToPost(widget.post.id, userId, 1);
                          debugPrint('userReaction DESPUÉS: ${context.read<PostProvider>().userReactionForPost(widget.post.id)}');
                        }
                      },
                    ),
                    Text('$likes', style: const TextStyle(fontSize: 12, color: AppColors.primaryOrange)),
                    const SizedBox(width: 8),
                    IconButton(
                      icon: Icon(
                        userReaction == 2 ? Icons.thumb_down_alt : Icons.thumb_down_alt_outlined,
                        size: 20,
                        color: userReaction == 2 ? AppColors.primaryOrange : AppColors.primaryOrange,
                      ),
                      onPressed: () async {
                        final userId = await AuthLocalDataSource().getUserId();
                        if (userId != null) {
                          context.read<PostProvider>().reactToPost(widget.post.id, userId, 2);
                        }
                      },
                    ),
                    Text('$dislikes', style: const TextStyle(fontSize: 12, color: AppColors.primaryOrange)),
                    const Spacer(),
                    TextButton.icon(
                      onPressed: () => Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => PostDetailPage(
                          post: widget.post,
                          isOwner: widget.isOwner,
                          communityId: widget.post.communityId,
                        )),
                      ),
                      icon: const Icon(Icons.chat_bubble_outline, size: 20, color: AppColors.darkBlue),
                      label: const Text('Comment', style: TextStyle(color: AppColors.darkBlue, fontSize: 13)),
                    ),
                  ],
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}
