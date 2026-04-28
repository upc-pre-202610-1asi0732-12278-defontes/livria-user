import 'package:local_auth/local_auth.dart';
import 'package:flutter/services.dart';

class BiometricHelper {
  static final LocalAuthentication _auth = LocalAuthentication();

  static Future<bool> canCheckBiometrics() async {
    try {
      return await _auth.canCheckBiometrics;
    } on PlatformException catch (e) {
      print(e);
      return false;
    }
  }

  static Future<bool> isDeviceSupported() async {
    return await _auth.isDeviceSupported();
  }

  static Future<bool> authenticate() async {
    final bool canCheck = await _auth.canCheckBiometrics;
    final bool isSupported = await _auth.isDeviceSupported();

    if (!canCheck && !isSupported) return false;

    try {
      return await _auth.authenticate(
        localizedReason: 'Please authenticate to access Livria',
      );
    } on PlatformException catch (e) {
      print(e);
      return false;
    }
  }
}
