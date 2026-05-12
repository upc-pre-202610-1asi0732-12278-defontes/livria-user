import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:provider/provider.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:livria_user/common/theme/app_colors.dart';
import 'package:livria_user/features/communities/infrastructure/datasource/community_remote_datasource.dart';
import '../../../auth/infrastructure/model/user_model.dart';
import '../../domain/entities/community.dart';
import '../../domain/entities/post.dart';
import '../../../auth/infrastructure/datasource/auth_local_datasource.dart';
import '../../../auth/infrastructure/datasource/auth_remote_datasource.dart';
import '../../domain/repositories/community_repository.dart';
import '../../domain/repositories/community_repository_impl.dart';
import '../../infrastructure/datasource/post_remote_datasource.dart';
import '../../domain/repositories/post_repository_impl.dart';
import '../providers/post_provider.dart';
import '../widgets/_community_header.dart';
import '../widgets/_post_form.dart';
import '../widgets/_post_list.dart';

String _getCommunityTypeLabel(int type) {
  switch (type) {
    case 1: return 'LITERATURE';
    case 2: return 'NON-FICTION';
    case 3: return 'FICTION';
    case 4: return 'MANGAS & COMICS';
    case 5: return 'JUVENILE';
    case 6: return 'CHILDREN';
    case 7: return 'EBOOKS & AUDIOBOOKS';
    default: return 'GENERAL';
  }
}

class CommunityDetailPage extends StatefulWidget {
  final Community community;
  final AuthLocalDataSource authLocalDataSource;
  final AuthRemoteDataSource authRemoteDataSource;
  final PostRemoteDataSource postRemoteDataSource;
  final CommunityRemoteDataSource communityRemoteDataSource;

  const CommunityDetailPage({
    super.key,
    required this.community,
    required this.authLocalDataSource,
    required this.authRemoteDataSource,
    required this.postRemoteDataSource,
    required this.communityRemoteDataSource,
  });

  @override
  State<CommunityDetailPage> createState() => _CommunityDetailPageState();
}

class _CommunityDetailPageState extends State<CommunityDetailPage> {
  String? _username;
  String? _userIconUrl;
  bool _isUserLoading = true;
  final TextEditingController _contentController = TextEditingController();
  bool _isPosting = false;
  File? _selectedImageFile;
  final ImagePicker _picker = ImagePicker();
  List<Post> _posts = [];
  bool _isLoadingPosts = true;
  late final PostRepositoryImpl _postRepository;

  late final CommunityRepository _communityRepository;
  int? _currentUserId;
  bool _isJoined = false;
  bool _isTogglingJoin = false;

  @override
  void initState() {
    super.initState();
    _communityRepository = CommunityRepositoryImpl(widget.communityRemoteDataSource);
    _postRepository = PostRepositoryImpl(widget.postRemoteDataSource);
    _loadUserProfile();
    _fetchPosts();
  }

  @override
  void dispose() {
    _contentController.dispose();
    super.dispose();
  }

  Future<void> _handleGalleryPick() async {
    try {
      final XFile? pickedFile = await _picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 70,
      );
      if (pickedFile != null) {
        if (mounted) {
          setState(() {
            _selectedImageFile = File(pickedFile.path);
          });
          _showSnackbar('Image selected', color: AppColors.softTeal);
        }
      }
    } catch (e) {
      print('Error al seleccionar imagen: $e');
      _showSnackbar('Failed to access gallery.', color: Colors.red);
    }
  }

  Future<void> _removeSelectedImage() async {
    if (mounted) {
      setState(() {
        _selectedImageFile = null;
      });
    }
    _showSnackbar('Image removed.', color: AppColors.softTeal);
  }

  Future<void> _fetchPosts() async {
    if (mounted) {
      setState(() {
        _isLoadingPosts = true;
      });
    }
    try {
      final fetchedPosts = await _postRepository.fetchPostsByCommunityId(widget.community.id, 0, 20);
      if (mounted) {
        setState(() {
          _posts = fetchedPosts;
          _isLoadingPosts = false;
        });
      }
    } catch (e) {
      print('Error al cargar posts: $e');
      if (mounted) {
        setState(() {
          _isLoadingPosts = false;
        });
      }
    }
  }

  Future<void> _loadUserProfile() async {
    try {
      final userId = await widget.authLocalDataSource.getUserId();
      final token = await widget.authLocalDataSource.getToken();

      if (userId != null && token != null) {
        final UserModel user = await widget.authRemoteDataSource.getUserProfile(userId, token);

        if (mounted) {
          setState(() {
            _currentUserId = userId;
            _username = user.username;
            _userIconUrl = user.icon;
            _isUserLoading = false;
          });
          _checkUserJoinedStatus();
        }
      } else {
        if (mounted) {
          setState(() {
            _isUserLoading = false;
          });
        }
      }
    } catch (e) {
      print('Error al cargar perfil de usuario: $e');
      if (mounted) {
        setState(() {
          _isUserLoading = false;
        });
      }
    }
  }

  Future<void> _handlePostCreation() async {
    final userId = await widget.authLocalDataSource.getUserId();
    final content = _contentController.text.trim();

    if (_username == null) {
      _showSnackbar('Error: The username could not be retrieved. Please try logging in again.', color: Colors.red);
      return;
    }

    if (content.isEmpty && _selectedImageFile == null) {
      _showSnackbar('The post cannot be empty. Enter content or select an image.', color: AppColors.secondaryYellow);
      return;
    }

    if (mounted) setState(() => _isPosting = true);

    try {
      String? imageBase64;
      if (_selectedImageFile != null) {
        final bytes = await _selectedImageFile!.readAsBytes();
        imageBase64 = "data:image/jpeg;base64,${base64Encode(bytes)}";
      }

      final success = await context.read<PostProvider>().addPost(
        communityId: widget.community.id,
        userId: _currentUserId!,
        username: _username!,
        content: content,
        img: imageBase64,
      );

      if (success) {
        _contentController.clear();
        if (mounted) setState(() => _selectedImageFile = null);
        _showSnackbar('Post successfully published!', color: AppColors.primaryOrange);
      }
    } catch (e) {
      _showSnackbar('Error publishing post: $e', color: Colors.red);
    } finally {
      if (mounted) setState(() => _isPosting = false);
    }
  }

  void _showSnackbar(String message, {required Color color}) {
    String cleanMessage = message.replaceFirst('Exception: ', '');
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(cleanMessage),
        backgroundColor: color,
        duration: const Duration(seconds: 3),
      ),
    );
  }

  void _handleJoinPressed() async {
    if (_currentUserId == null) {
      _showSnackbar('User ID not available. Please try logging in again.', color: Colors.red);
      return;
    }
    if (_isTogglingJoin) return;

    setState(() {
      _isTogglingJoin = true;
    });

    try {
      if (_isJoined) {
        // LEAVE
        await _communityRepository.leaveCommunity(
          userClientId: _currentUserId!,
          communityId: widget.community.id,
        );
        if (mounted) {
          setState(() {
            _isJoined = false;
          });
          _showSnackbar('You have left the community ${widget.community.name}.',
              color: AppColors.secondaryYellow);
        }
      } else {
        // JOIN
        await _communityRepository.joinCommunity(
          userClientId: _currentUserId!,
          communityId: widget.community.id,
        );
        if (mounted) {
          setState(() {
            _isJoined = true;
          });
          _showSnackbar('You have successfully joined the community ${widget.community.name}!',
              color: AppColors.primaryOrange);
        }
      }
    } catch (e) {
      _showSnackbar('Operation failed: ${e.toString()}', color: Colors.red);
    } finally {
      if (mounted) {
        setState(() {
          _isTogglingJoin = false;
        });
      }
    }
  }

  Future<void> _checkUserJoinedStatus() async {
    if (_currentUserId == null) return;

    try {
      final isMember = await _communityRepository.checkUserJoined(
        userId: _currentUserId!,
        communityId: widget.community.id,
      );
      if (mounted) {
        setState(() {
          _isJoined = isMember;
        });
      }
    } catch (e) {
      print('Error al verificar unión a comunidad: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.white,
      appBar: AppBar(
        backgroundColor: AppColors.white,
        elevation: 0,
        title: Text(widget.community.name, style: const TextStyle(color: AppColors.darkBlue)),
        iconTheme: const IconThemeData(color: AppColors.darkBlue),
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            CommunityHeader(
              community: widget.community,
              getCommunityTypeLabel: _getCommunityTypeLabel,
              onJoinPressed: _isTogglingJoin ? () {} : _handleJoinPressed,
              isJoined: _isJoined,
            ),
            SizedBox(height: 20),
            const Divider(height: 1, thickness: 2, color: AppColors.softTeal),
            SizedBox(height: 20),

            // FORMULARIO DE POST
            PostForm(
              isUserLoading: _isUserLoading,
              username: _username,
              isPosting: _isPosting,
              contentController: _contentController,
              selectedImageFile: _selectedImageFile,
              onGalleryPick: _handleGalleryPick,
              onRemoveImage: _removeSelectedImage,
              onPost: _handlePostCreation,
              onCameraPressed: _handleCameraPick,
              showSnackbar: _showSnackbar,
            ),

            SizedBox(height: 20),
            const Divider(height: 1, thickness: 2, color: AppColors.lightGrey),
            SizedBox(height: 20),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: Text(
                'Recent Posts',
                style: Theme.of(context).textTheme.titleLarge!.copyWith(
                  color: AppColors.darkBlue,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            SizedBox(height: 20),

            PostList(
              communityId: widget.community.id,
              currentUserId: _currentUserId,
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _handleCameraPick() async {
    try {
      final XFile? pickedFile = await _picker.pickImage(
        source: ImageSource.camera,
        imageQuality: 70,
      );

      if (pickedFile != null) {
        if (mounted) {
          setState(() {
            _selectedImageFile = File(pickedFile.path);
          });
        }
      }
    } catch (e) {
      print('Error al tomar foto: $e');
      _showSnackbar('Failed to open camera.', color: Colors.red);
    }
  }
}


