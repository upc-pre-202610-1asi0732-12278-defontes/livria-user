// features/communities/presentation/widgets/user_avatar.dart
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:livria_user/common/theme/app_colors.dart';
import '../../../auth/infrastructure/datasource/auth_local_datasource.dart';
import '../../../auth/infrastructure/datasource/auth_remote_datasource.dart';

class UserAvatar extends StatefulWidget {
  final int userId;
  final double radius;
  final String? knownIconUrl;

  const UserAvatar({
    super.key,
    required this.userId,
    this.radius = 18,
    this.knownIconUrl,
  });

  @override
  State<UserAvatar> createState() => _UserAvatarState();
}

class _UserAvatarState extends State<UserAvatar> {
  String? _iconData;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    if (widget.knownIconUrl != null &&
        widget.knownIconUrl!.isNotEmpty &&
        !widget.knownIconUrl!.contains('cdn-icons-png')) {
      _iconData = widget.knownIconUrl;
    } else {
      _fetchIcon();
    }
  }

  Future<void> _fetchIcon() async {
    if (widget.userId <= 0) return;
    if (mounted) setState(() => _isLoading = true);
    try {
      final token = await AuthLocalDataSource().getToken();
      if (token != null) {
        final user = await AuthRemoteDataSource().getUserProfile(widget.userId, token);
        if (mounted && user.icon != null && user.icon != 'string') {
          setState(() => _iconData = user.icon);
        }
      }
    } catch (e) {
      debugPrint('UserAvatar fetch error: $e');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Widget _buildImage(String data) {
    if (data.isEmpty || data == 'string') return _defaultIcon();

    if (data.length > 60 && !data.startsWith('http')) {
      try {
        final clean = data.contains(',') ? data.split(',').last : data;
        return Image.memory(
          base64Decode(clean.trim()),
          width: widget.radius * 2,
          height: widget.radius * 2,
          fit: BoxFit.cover,
          errorBuilder: (_, __, ___) => _defaultIcon(),
        );
      } catch (_) { return _defaultIcon(); }
    }

    return Image.network(
      data,
      width: widget.radius * 2,
      height: widget.radius * 2,
      fit: BoxFit.cover,
      errorBuilder: (_, __, ___) => _defaultIcon(),
    );
  }

  Widget _defaultIcon() => Icon(Icons.account_circle, color: AppColors.softTeal, size: widget.radius * 2);

  @override
  Widget build(BuildContext context) {
    return CircleAvatar(
      radius: widget.radius,
      backgroundColor: AppColors.softTeal.withOpacity(0.2),
      child: ClipOval(
        child: _isLoading
            ? SizedBox(
          width: widget.radius,
          height: widget.radius,
          child: const CircularProgressIndicator(strokeWidth: 2),
        )
            : _iconData != null
            ? _buildImage(_iconData!)
            : _defaultIcon(),
      ),
    );
  }
}