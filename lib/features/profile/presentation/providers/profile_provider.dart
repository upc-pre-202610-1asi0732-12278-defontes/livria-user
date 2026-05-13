import 'dart:io';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:livria_user/common/services/cloudinary_upload_service.dart';
import 'package:livria_user/features/communities/domain/entities/community.dart';
import 'package:livria_user/features/communities/domain/usecases/get_communities_usecase.dart';
import '../../../auth/infrastructure/datasource/auth_local_datasource.dart';
import '../../../orders/application/services/payment_service.dart';
import '../../../orders/domain/entities/order.dart';
import '../../../orders/domain/usecases/get_user_orders_usecase.dart';
import '../../domain/entities/user_profile.dart';
import '../../domain/repositories/profile_repository.dart';
import 'package:image_picker/image_picker.dart';

class ProfileProvider extends ChangeNotifier {
  // Dependencias
  final ProfileRepository profileRepository;
  final GetUserOrdersUseCase getUserOrdersUseCase;
  final GetCommunitiesUseCase getCommunitiesUseCase;

  ProfileProvider({
    required this.profileRepository,
    required this.getUserOrdersUseCase,
    required this.getCommunitiesUseCase,
  });

  // ESTADO
  UserProfile? _user;
  List<Order> _orders = [];
  List<Community> _communities = [];
  bool _isLoading = true;
  int _selectedTab = 0; // 0: My Orders, 1: Edit Bio

  final TextEditingController displayController = TextEditingController();
  final TextEditingController usernameController = TextEditingController();
  final TextEditingController phraseController = TextEditingController();
  final TextEditingController emailController = TextEditingController();
  final TextEditingController iconController = TextEditingController();

  // GETTERS
  UserProfile? get user => _user;
  List<Order> get orders => _orders;
  List<Community> get communities => _communities;
  bool get isLoading => _isLoading;
  int get selectedTab => _selectedTab;



  Future<void> pickImage(BuildContext context) async {
    try {
      final ImagePicker picker = ImagePicker();
      final XFile? image = await picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 50,
      );

      if (image != null) {
        final file = File(image.path);
        final url = await CloudinaryUploadService.uploadFile(file);
        if (url == null) {
          if (context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('No se pudo subir la imagen. Revisa tu conexión.'),
              ),
            );
          }
          return;
        }
        iconController.text = url;

        if (_user != null) {
          _user = _user!.copyWith(icon: url);
        }
        notifyListeners();
      }
    } catch (e) {
      debugPrint("Error picking image: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Could not pick image")),
      );
    }
  }


  // INICIO
  Future<void> loadData() async {
    _isLoading = true;
    notifyListeners();

    try {
      final userId = await AuthLocalDataSource().getUserId();
      if (userId == null) throw Exception("No user logged in");

      _user = await profileRepository.getUserProfile(userId);
      _fillControllers();

      try {
        _orders = await getUserOrdersUseCase(userId);
      } catch (e) {
        debugPrint('Error loading orders: $e');
        _orders = [];
      }

      try {
        _communities = await getCommunitiesUseCase(userId);
      } catch (e) {
        debugPrint('Error loading communities: $e');
        _communities = [];
      }

      _isLoading = false;
    } catch (e) {
      debugPrint("Error loading profile: $e");
      _isLoading = false;
    }
    notifyListeners();
  }

  void _fillControllers() {
    if (_user != null) {
      displayController.text = _user!.display;
      usernameController.text = _user!.username;
      phraseController.text = _user!.phrase;
      emailController.text = _user!.email;
      iconController.text = _user!.icon;
    }
  }

  void changeTab(int index) {
    _selectedTab = index;
    notifyListeners();
  }

  Future<bool> saveProfileChanges(BuildContext context) async {
    if (_user == null) return false;

    _isLoading = true;
    notifyListeners();

    try {
      final updatedProfile = _user!.copyWith(
        display: displayController.text,
        username: usernameController.text,
        phrase: phraseController.text,
        email: emailController.text,
        icon: iconController.text,
      );

      final newUser = await profileRepository.updateUserProfile(_user!.id, updatedProfile);

      _user = newUser;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Profile updated successfully!"), backgroundColor: Colors.green),
      );

      _isLoading = false;
      notifyListeners();
      return true;

    } catch (e) {
      _isLoading = false;
      notifyListeners();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error updating profile: $e"), backgroundColor: Colors.red),
      );
      return false;
    }
  }

  Future<bool> removeCommunity(BuildContext context, int communityId) async {
    if (_user == null) return false;

    try {
      await profileRepository.deleteCommunity(communityId, _user!.id);
      _communities.removeWhere((item) => item.id == communityId);
      notifyListeners();

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Community deleted successfully"),
          backgroundColor: Colors.green,
        ),
      );

      return true;
    } catch (e) {
      debugPrint("Error deleting community: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text("Error deleting community: $e"),
            backgroundColor: Colors.red
        ),
      );
      return false;
    }
  }


  Future<bool> deleteAccount(BuildContext context) async {
    if (_user == null) return false;

    try {
      await profileRepository.deleteAccount(_user!.id);

      await AuthLocalDataSource().clearAuthData();

      return true;
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error deleting account: $e"), backgroundColor: Colors.red),
      );
      return false;
    }
  }

  Future<void> logout() async {
    await AuthLocalDataSource().clearAuthData();
  }

  Future<bool> changeSubscriptionPlan(String newPlan) async {
    if (_user == null) return false;
    _isLoading = true;
    notifyListeners();

    try {
      final updatedUser = await profileRepository.updateSubscription(_user!.id, newPlan);
      _user = updatedUser;
      _isLoading = false;
      notifyListeners();
      return true; // ÉXITO
    } catch (e) {
      debugPrint("Error updating plan: $e");
      _isLoading = false;
      notifyListeners();
      return false; // FALLO
    }
  }

  // PAYMENT
  Future<bool> submitSubscriptionPaymentProof(BuildContext context, File proof) async {
    _isLoading = true;
    notifyListeners();

    try {
      final paymentService = PaymentService();

      final imageUrl = await paymentService.uploadToCloudinary(proof);
      if (imageUrl == null) throw Exception("Failed to upload image.");

      final emailSent = await paymentService.sendEmail(
        serviceId: 'service_4t97z5d',
        templateId: 'template_kgn4xci',
        publicKey: '9sYY-fTEKMm4wPX-k',
        params: {
          'payment_type': 'SUBSCRIPTION PAYMENT',
          'intro_text': 'A subscription payment proof has been submitted and requires verification.',
          'full_name': _user?.display ?? '',
          'email': _user?.email ?? '',
          'phone': '-',
          'order_details': 'Community Plan - S/ 19.90/month',
          'user_id': '${_user?.id ?? ''}',
          'submitted_date': DateFormat('dd/MM/yyyy HH:mm').format(DateTime.now()),
          'total_amount': 'S/ 19.90',
          'my_file': imageUrl,
        },
      );

      if (!emailSent) throw Exception("Failed to send email.");

      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      debugPrint("Error submitting subscription proof: $e");
      _isLoading = false;
      notifyListeners();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error: $e"), backgroundColor: Colors.red),
      );
      return false;
    }
  }
}