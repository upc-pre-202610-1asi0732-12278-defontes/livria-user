import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:livria_user/features/auth/infrastructure/datasource/auth_remote_datasource.dart';
import '../../../../common/theme/app_colors.dart';
import '../../domain/entities/review.dart';
import 'package:livria_user/features/auth/infrastructure/datasource/auth_local_datasource.dart';

class ReviewCard extends StatefulWidget {
  final Review review;
  final String? userIconUrl;

  const ReviewCard({super.key, required this.review, this.userIconUrl});

  @override
  State<ReviewCard> createState() => _ReviewCardState();
}

class _ReviewCardState extends State<ReviewCard> {
  String? _fetchedIconData;
  bool _isLoadingIcon = false;

  @override
  void initState() {
    super.initState();
    _checkAndFetchIcon();
  }

  void _checkAndFetchIcon() {
    // Si es mi propia reseña (inyectada) y es válida, no hacemos nada más.
    if (widget.userIconUrl != null && widget.userIconUrl!.length > 10 && widget.userIconUrl != "string") {
      return;
    }

    // Si la reseña ajena no tiene icono real, lo buscamos por ID.
    final bool isInvalid = widget.review.userIcon == null || 
                           widget.review.userIcon!.isEmpty || 
                           widget.review.userIcon == "string";

    if (isInvalid && widget.review.userId > 0) {
      _fetchUserIcon();
    }
  }

  Future<void> _fetchUserIcon() async {
    if (mounted) setState(() => _isLoadingIcon = true);
    try {
      final authLocal = AuthLocalDataSource();
      final token = await authLocal.getToken();
      if (token != null) {
        final authRemote = AuthRemoteDataSource();
        // Buscamos el perfil del autor de la reseña
        final user = await authRemote.getUserProfile(widget.review.userId, token);
        if (mounted && user.icon != null && user.icon != "string") {
          setState(() {
            _fetchedIconData = user.icon;
          });
        }
      }
    } catch (e) {
      debugPrint('Error ReviewCard: $e');
    } finally {
      if (mounted) setState(() => _isLoadingIcon = false);
    }
  }

  Widget _buildAvatarImage(String iconData) {
    if (iconData.isEmpty || iconData == "string") return _buildDefaultIcon();

    // SOPORTE PARA BASE64 (La cadena larga de tu Swagger)
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
    // Prioridad: 1. Imagen inyectada, 2. Imagen descargada del perfil, 3. Imagen de la reseña
    String? displayData = (widget.userIconUrl != null && widget.userIconUrl != "string") 
        ? widget.userIconUrl 
        : (_fetchedIconData ?? widget.review.userIcon);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 32.0, vertical: 8.0),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(12.0),
            decoration: BoxDecoration(
                color: AppColors.lightGrey,
                borderRadius: BorderRadius.circular(8.0),
                border: Border.all(color: AppColors.lightGrey)
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    CircleAvatar(
                      radius: 18,
                      backgroundColor: AppColors.softTeal.withOpacity(0.2),
                      child: ClipOval(
                        child: _isLoadingIcon 
                          ? const SizedBox(width: 15, height: 15, child: CircularProgressIndicator(strokeWidth: 2))
                          : (displayData != null && displayData != "string") 
                              ? _buildAvatarImage(displayData)
                              : _buildDefaultIcon(),
                      ),
                    ),
                    const SizedBox(width: 10.0),
                    Text('@${widget.review.username}',
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: AppColors.primaryOrange),
                    ),
                    const Spacer(),
                    Text(widget.review.stars.toString(),
                        style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.accentGold)
                    ),
                    const Icon(Icons.star, color: AppColors.accentGold, size: 16),
                  ],
                ),
                const SizedBox(height: 8.0),
                Text(widget.review.content,
                  textAlign: TextAlign.justify,
                  style: const TextStyle(fontSize: 14, color: AppColors.black),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16.0),
        ],
      ),
    );
  }
}
