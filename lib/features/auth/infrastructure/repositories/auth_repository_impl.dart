import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:livria_user/common/services/cloudinary_upload_service.dart';
import '../../domain/entities/user_entity.dart';
import '../../domain/repositories/auth_repository.dart';
import '../datasource/auth_local_datasource.dart';
import '../datasource/auth_remote_datasource.dart';

class AuthRepositoryImpl implements AuthRepository {
  final AuthRemoteDataSource remoteDataSource;
  final AuthLocalDataSource localDataSource;

  AuthRepositoryImpl({
    required this.remoteDataSource,
    required this.localDataSource
});

  // --- Login ---
  @override
  Future<UserEntity> login(String username, String password) async {
    final loginResponse = await remoteDataSource.signIn(username, password);

    final String token = loginResponse['token'];
    final int userId = loginResponse['userId'];

    await localDataSource.saveAuthgData(token: token, userId: userId);

    final userModel = await remoteDataSource.getUserProfile(userId, token);
    return userModel;
  }

  // --- Register ---
  @override
  Future<UserEntity> register({
    required String email,
    required String password,
    required String username,
    required String display,
    String? phrase,
    String? iconPath
}) async {
    String? iconUrl;

    if (iconPath != null && iconPath.isNotEmpty) {
      try {
        final File imageFile = File(iconPath);
        iconUrl = await CloudinaryUploadService.uploadFile(imageFile);
      } catch (e) {
        debugPrint('Error subiendo icono a Cloudinary: $e');
        iconUrl = null;
      }
    }
    if (iconUrl != null) {
      debugPrint('Icono Cloudinary URL length: ${iconUrl.length}');
    }

    final registerData = {
      "email": email,
      "username": username,
      "display": display,
      "password": password,
      "confirmPassword": password,
      "phrase": phrase ?? "",
      "icon": iconUrl,
    };

    await remoteDataSource.register(registerData);

    return await login(username, password);
  }

  // --- Check Authentication Status ---
  @override
  Future<UserEntity?> checkAuthStatus() async {
    try {
      final token = await localDataSource.getToken();
      final userId = await localDataSource.getUserId();

      if (token == null || userId == null) {
        return null;
      }
      final userModel = await remoteDataSource.getUserProfile(userId, token);
      return userModel;
    } catch (e) {
      await localDataSource.clearAuthData();
      return null;
    }
  }

  // --- Logout ---
  @override
  Future<void> logout() async {
    await localDataSource.clearAuthData();
}
}