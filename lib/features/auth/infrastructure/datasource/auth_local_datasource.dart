import 'package:shared_preferences/shared_preferences.dart';
// librería para almacenamiento local simple (clave-valor) en la app.

class AuthLocalDataSource {

  static const String _tokenKey = 'AUTH_TOKEN';
  static const String _userIdKey = 'USER_ID';
  static const String _biometricsEnabledKey = 'BIOMETRICS_ENABLED';

  // --- Guardar datos (Login Exitoso) ---
  Future<void> saveAuthgData({required String token, required int userId}) async {
    // Obtiene la instancia de SharedPreferences
    final prefs = await SharedPreferences.getInstance();
    // Guarda el token JWT como String
    await prefs.setString(_tokenKey, token);
    // Guarda el id del usuario como int
    await prefs.setInt(_userIdKey, userId);
  }

  // --- Obtener token al abrir la app ---
  Future<String?> getToken() async {
    final prefs = await SharedPreferences.getInstance();
    // Devuelve el token si existe, sino null
    return prefs.getString(_tokenKey);
  }

  // --- Obtener userId al abrir la app ---
  Future<int?> getUserId() async {
    final prefs = await SharedPreferences.getInstance();
    // Devuelve el userId si existe, sino null
    return prefs.getInt(_userIdKey);
  }

  // --- Logout / Borrar datos ---
  Future<void> clearAuthData() async {
    final prefs = await SharedPreferences.getInstance();
    // Borra token y userId del almacenamiento local
    await prefs.remove(_tokenKey);
    await prefs.remove(_userIdKey);
    await prefs.remove(_biometricsEnabledKey);
  }

  // --- Biometría ---
  Future<void> setBiometricsEnabled(bool enabled) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_biometricsEnabledKey, enabled);
  }

  Future<bool> isBiometricsEnabled() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_biometricsEnabledKey) ?? false;
  }

}
