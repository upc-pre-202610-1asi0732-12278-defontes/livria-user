import 'dart:convert'; // para convertir imágenes a base64
import 'dart:io'; // para manejar archivos locales
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
    String? iconBase64;

    if (iconPath != null && iconPath.isNotEmpty) {
      try {
        final File imageFile = File(iconPath);
        final List<int> imageBytes = await imageFile.readAsBytes();

        final String base64String = base64Encode(imageBytes);
        iconBase64 = "data:image/jpeg;base64,$base64String";

      } catch (e) {
        print("Error convirtiendo imagen a Base64: $e");
        iconBase64 = null;
      }
    }
    if (iconBase64 != null) {
      print("📦 Longitud del Base64 a enviar: ${iconBase64.length} caracteres");
      // Imprime solo los primeros 100 caracteres para ver si tiene el prefijo o no
      print("📦 Inicio del Base64: ${iconBase64.substring(0, 100)}...");
    }

    final registerData = {
      "email": email,
      "username": username,
      "display": display,
      "password": password,
      "confirmPassword": password,
      "phrase": phrase ?? "",
      "icon": iconBase64,
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