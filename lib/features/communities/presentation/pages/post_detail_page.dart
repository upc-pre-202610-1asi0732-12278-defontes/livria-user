// features/communities/presentation/pages/post_detail_page.dart
import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:livria_user/common/theme/app_colors.dart';
import '../../domain/entities/post.dart';
import '../../domain/entities/comment.dart';
import '../../../auth/infrastructure/datasource/auth_local_datasource.dart';
import '../providers/post_provider.dart';
import '../widgets/use_avatar.dart';

class PostDetailPage extends StatefulWidget {
  final Post post;
  final bool isOwner;
  final VoidCallback? onDelete;
  final VoidCallback? onEdit;

  const PostDetailPage({
    super.key,
    required this.post,
    this.isOwner = false,
    this.onDelete,
    this.onEdit,
  });

  @override
  State<PostDetailPage> createState() => _PostDetailPageState();
}

class _PostDetailPageState extends State<PostDetailPage> {
  final TextEditingController _commentController = TextEditingController();
  bool _isSending = false;
  int? _currentUserId;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<PostProvider>().loadComments(widget.post.id);
    });
    _loadUserId();
  }

  Future<void> _loadUserId() async {
    final id = await AuthLocalDataSource().getUserId();
    if (mounted) setState(() => _currentUserId = id);
  }

  @override
  void dispose() {
    _commentController.dispose();
    super.dispose();
  }

  String _formatTimestamp(dynamic timestamp) {
    try {
      if (timestamp == null) return 'Unknown date';
      final String utc = timestamp.toString().endsWith('Z')
          ? timestamp.toString()
          : '${timestamp}Z';
      return DateFormat('dd/MM/yyyy \'at\' HH:mm').format(DateTime.parse(utc).toLocal());
    } catch (_) { return 'Unknown date'; }
  }

  Widget _buildPostImage(String img) {
    if (img.isEmpty || img == 'string') return const SizedBox();
    try {
      if (img.startsWith('data:image') || (!img.startsWith('http') && img.length > 100)) {
        final base64Str = img.contains(',') ? img.split(',').last : img;
        return ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: Image.memory(base64Decode(base64Str), fit: BoxFit.cover, width: double.infinity),
        );
      }
      return ClipRRect(
        borderRadius: BorderRadius.circular(8),
        child: Image.network(img, fit: BoxFit.cover, width: double.infinity,
            errorBuilder: (_, __, ___) => const SizedBox()),
      );
    } catch (_) { return const SizedBox(); }
  }

  Future<void> _submitComment() async {
    final content = _commentController.text.trim();
    if (content.isEmpty || _currentUserId == null) return;

    setState(() => _isSending = true);
    final success = await context.read<PostProvider>().addComment(
      postId: widget.post.id,
      userId: _currentUserId!,
      content: content,
    );
    if (success && mounted) {
      _commentController.clear();
    }
    if (mounted) setState(() => _isSending = false);
  }

  void _showEditDialog() {
    final controller = TextEditingController(text: widget.post.content);
    File? selectedImage;
    String? currentImg = widget.post.img;

    showDialog(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text("Edit Post"),
          content: SizedBox(
            width: double.maxFinite,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: controller,
                    maxLines: 3,
                    decoration: const InputDecoration(hintText: "Write something..."),
                  ),
                  const SizedBox(height: 12),
                  if (selectedImage != null)
                    Stack(children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: Image.file(selectedImage!, height: 120, width: double.infinity, fit: BoxFit.cover),
                      ),
                      Positioned(top: 4, right: 4, child: GestureDetector(
                        onTap: () => setDialogState(() { selectedImage = null; currentImg = ""; }),
                        child: const CircleAvatar(radius: 12, backgroundColor: Colors.red,
                            child: Icon(Icons.close, size: 14, color: Colors.white)),
                      )),
                    ])
                  else if (currentImg != null && currentImg!.isNotEmpty && currentImg != "string")
                    Stack(children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: currentImg!.startsWith('data:image') || (!currentImg!.startsWith('http') && currentImg!.length > 100)
                            ? Image.memory(base64Decode(currentImg!.contains(',') ? currentImg!.split(',').last : currentImg!),
                            height: 120, width: double.infinity, fit: BoxFit.cover)
                            : Image.network(currentImg!, height: 120, width: double.infinity, fit: BoxFit.cover),
                      ),
                      Positioned(top: 4, right: 4, child: GestureDetector(
                        onTap: () => setDialogState(() => currentImg = ""),
                        child: const CircleAvatar(radius: 12, backgroundColor: Colors.red,
                            child: Icon(Icons.close, size: 14, color: Colors.white)),
                      )),
                    ]),
                  const SizedBox(height: 8),
                  TextButton.icon(
                    onPressed: () async {
                      final picker = ImagePicker();
                      final XFile? picked = await picker.pickImage(source: ImageSource.gallery, imageQuality: 70);
                      if (picked != null) setDialogState(() => selectedImage = File(picked.path));
                    },
                    icon: const Icon(Icons.image_outlined),
                    label: const Text("Change image"),
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(dialogContext), child: const Text("Cancel")),
            TextButton(
              onPressed: () async {
                String? finalImg = currentImg;
                if (selectedImage != null) {
                  final bytes = await selectedImage!.readAsBytes();
                  finalImg = "data:image/jpeg;base64,${base64Encode(bytes)}";
                }
                final success = await context.read<PostProvider>().editPost(
                  widget.post.id, controller.text, finalImg,
                );
                if (success && Navigator.canPop(dialogContext)) Navigator.pop(dialogContext);
              },
              child: const Text("Save"),
            ),
          ],
        ),
      ),
    );
  }

  void _confirmDelete(BuildContext context, int postId) {
    showDialog(
      context: context,
      builder: (dialogContext) =>
          AlertDialog(
            title: const Text("Delete Post"),
            content: const Text("Are you sure?"),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(dialogContext),
                child: const Text("Cancel"),
              ),
              TextButton(
                onPressed: () async {
                  final success = await context.read<PostProvider>().deletePost(
                      postId);

                  if (Navigator.canPop(dialogContext)) {
                    Navigator.pop(dialogContext);
                  }
                  if (success && Navigator.canPop(context)) {
                    Navigator.pop(context);
                  }
                  if (!success && context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                          content: Text("Error: Could not delete post")),
                    );
                  }
                },
                child: const Text(
                    "Delete", style: TextStyle(color: Colors.red)),
              ),
            ],
          ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // temporal, bórralo después
    debugPrint('isOwner: ${widget.isOwner}, postUserId: ${widget.post.userId}');
    final postProvider = context.watch<PostProvider>();
    final comments = postProvider.commentsForPost(widget.post.id);
    final isLoading = postProvider.isLoadingCommentsForPost(widget.post.id);

    return Scaffold(
      backgroundColor: AppColors.white,
      appBar: AppBar(
        backgroundColor: AppColors.white,
        elevation: 0,
        title: const Text('Post', style: TextStyle(color: AppColors.darkBlue)),
        iconTheme: const IconThemeData(color: AppColors.darkBlue),
        actions: [
          if (widget.isOwner) ...[
            IconButton(
              icon: const Icon(Icons.edit_outlined, color: AppColors.darkBlue),
              onPressed: _showEditDialog,
            ),
            IconButton(
              icon: const Icon(Icons.delete_outline, color: Colors.redAccent),
              onPressed: () => _confirmDelete(context, widget.post.id),
            ),
          ]
        ],
      ),
      body: Column(
        children: [
          // Contenido scrolleable
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // --- POST ---
                  Row(
                    children: [
                      UserAvatar(userId: widget.post.userId, radius: 18),
                      const SizedBox(width: 8),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('@${widget.post.username}',
                              style: Theme.of(context).textTheme.titleSmall!.copyWith(
                                  fontWeight: FontWeight.bold, color: AppColors.darkBlue)),
                          Text(_formatTimestamp(widget.post.createdAt),
                              style: Theme.of(context).textTheme.bodySmall!.copyWith(
                                  color: AppColors.black.withOpacity(0.6))),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Text(widget.post.content,
                      style: Theme.of(context).textTheme.bodyLarge!.copyWith(color: AppColors.black)),
                  if (widget.post.img.isNotEmpty && widget.post.img != 'string') ...[
                    const SizedBox(height: 12),
                    _buildPostImage(widget.post.img),
                  ],
                  const SizedBox(height: 20),
                  const Divider(thickness: 1.5, color: AppColors.lightGrey),
                  const SizedBox(height: 8),

                  // --- COMMENTS ---
                  Text('Comments',
                      style: Theme.of(context).textTheme.titleMedium!.copyWith(
                          fontWeight: FontWeight.bold, color: AppColors.darkBlue)),
                  const SizedBox(height: 12),

                  if (isLoading)
                    const Center(child: CircularProgressIndicator(color: AppColors.primaryOrange))
                  else if (comments.isEmpty)
                    Center(child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 24),
                      child: Text('No comments yet. Be the first!',
                          style: TextStyle(color: AppColors.black.withOpacity(0.5))),
                    ))
                  else
                    ListView.separated(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: comments.length,
                      separatorBuilder: (_, __) => const Divider(height: 1, color: AppColors.lightGrey),
                      itemBuilder: (context, index) => _CommentTile(
                        comment: comments[index],
                        formatTimestamp: _formatTimestamp,
                      ),
                    ),
                ],
              ),
            ),
          ),

          // --- INPUT COMENTARIO ---
          Container(
            padding: EdgeInsets.only(
              left: 16, right: 8,
              top: 8,
              bottom: MediaQuery.of(context).viewInsets.bottom + 8,
            ),
            decoration: BoxDecoration(
              color: AppColors.white,
              border: Border(top: BorderSide(color: AppColors.lightGrey, width: 1.5)),
            ),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _commentController,
                    decoration: InputDecoration(
                      hintText: 'Write a comment...',
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(24)),
                      focusColor: AppColors.accentGold,
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                    ),
                    maxLines: null,
                    textInputAction: TextInputAction.send,
                    onSubmitted: (_) => _submitComment(),
                  ),
                ),
                const SizedBox(width: 8),
                _isSending
                    ? const SizedBox(width: 24, height: 24,
                    child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.primaryOrange))
                    : IconButton(
                  icon: const Icon(Icons.send_rounded, color: AppColors.primaryOrange),
                  onPressed: _submitComment,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _CommentTile extends StatelessWidget {
  final Comment comment;
  final String Function(dynamic) formatTimestamp;

  const _CommentTile({required this.comment, required this.formatTimestamp});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          UserAvatar(userId: comment.userId, radius: 16),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text('@${comment.username}',
                        style: Theme.of(context).textTheme.titleSmall!.copyWith(
                            fontWeight: FontWeight.bold, color: AppColors.darkBlue)),
                    const SizedBox(width: 8),
                    Text(formatTimestamp(comment.createdAt),
                        style: Theme.of(context).textTheme.bodySmall!.copyWith(
                            color: AppColors.black.withOpacity(0.5))),
                  ],
                ),
                const SizedBox(height: 4),
                Text(comment.content,
                    style: Theme.of(context).textTheme.bodyMedium!.copyWith(color: AppColors.black)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}