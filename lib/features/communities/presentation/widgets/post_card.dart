import 'package:flutter/material.dart';
import '../../domain/entities/post.dart';
import 'package:livria_user/common/theme/app_colors.dart';
import 'package:intl/intl.dart';
import 'dart:convert';
import 'dart:typed_data';
import 'package:livria_user/features/auth/infrastructure/datasource/auth_local_datasource.dart';
import 'package:livria_user/features/auth/infrastructure/datasource/auth_remote_datasource.dart';

class PostCard extends StatefulWidget {
  final Post post;
  final String? userIconUrl;

  const PostCard({
    super.key,
    required this.post,
    this.userIconUrl,
  });

  @override
  State<PostCard> createState() => _PostCardState();
}

class _PostCardState extends State<PostCard> {
  String? _fetchedIconData;
  bool _isLoadingIcon = false;

  @override
  void initState() {
    super.initState();
    // Si no tenemos el icono inyectado (del usuario actual), buscamos el perfil del autor
    if (widget.userIconUrl == null || widget.userIconUrl!.isEmpty || widget.userIconUrl!.contains('cdn-icons-png')) {
      _fetchUserIcon();
    }
  }

  Future<void> _fetchUserIcon() async {
    if (widget.post.userId <= 0) return;
    
    if (mounted) setState(() => _isLoadingIcon = true);
    try {
      final authLocal = AuthLocalDataSource();
      final token = await authLocal.getToken();
      if (token != null) {
        final authRemote = AuthRemoteDataSource();
        final user = await authRemote.getUserProfile(widget.post.userId, token);
        if (mounted && user.icon != null && user.icon != "string") {
          setState(() {
            _fetchedIconData = user.icon;
          });
        }
      }
    } catch (e) {
      debugPrint('Error PostCard Icon Fetch: $e');
    } finally {
      if (mounted) setState(() => _isLoadingIcon = false);
    }
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

  Widget _buildAvatarImage(String iconData) {
    if (iconData.isEmpty || iconData == "string") return _buildDefaultIcon();

    // SOPORTE PARA BASE64
    if (iconData.length > 60 && !iconData.startsWith('http')) {
      try {
        String cleanBase64 = iconData;
        if (iconData.contains(',')) {
          cleanBase64 = iconData.split(',').last;
        }
        return Image.memory(
          base64Decode(cleanBase64.trim()),
          width: 36,
          height: 36,
          fit: BoxFit.cover,
          errorBuilder: (context, error, stackTrace) => _buildDefaultIcon(),
        );
      } catch (e) {
        return _buildDefaultIcon();
      }
    }

    // SOPORTE PARA URL
    final String fullUrl = iconData.startsWith('http') 
        ? iconData 
        : 'https://lililivria.azurewebsites.net/${iconData.startsWith('/') ? iconData.substring(1) : iconData}';

    return Image.network(
      fullUrl,
      width: 36,
      height: 36,
      fit: BoxFit.cover,
      errorBuilder: (context, error, stackTrace) => _buildDefaultIcon(),
    );
  }

  Widget _buildDefaultIcon() {
    return const Icon(Icons.account_circle, color: AppColors.softTeal, size: 36);
  }

  @override
  Widget build(BuildContext context) {
    const double borderRadius = 12.0;
    const double avatarRadius = 18.0;

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
                CircleAvatar(
                  radius: avatarRadius,
                  backgroundColor: AppColors.softTeal.withOpacity(0.2),
                  child: ClipOval(
                    child: _isLoadingIcon 
                      ? const SizedBox(width: 15, height: 15, child: CircularProgressIndicator(strokeWidth: 2))
                      : (effectiveIconData != null) 
                          ? _buildAvatarImage(effectiveIconData)
                          : _buildDefaultIcon(),
                  ),
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
            if (widget.post.img != null && widget.post.img!.isNotEmpty && widget.post.img != "string") ...[
              const SizedBox(height: 12),
              ClipRRect(
                borderRadius: BorderRadius.circular(8.0),
                child: Builder(
                  builder: (context) {
                    final imageStr = widget.post.img!;
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
          ],
        ),
      ),
    );
  }
}
