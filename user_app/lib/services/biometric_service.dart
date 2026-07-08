import 'package:flutter/services.dart';
import 'package:local_auth/local_auth.dart';

class BiometricService {
  final LocalAuthentication _auth = LocalAuthentication();

  /// Checks if the device supports biometric authentication and if any are enrolled.
  Future<bool> canAuthenticate() async {
    try {
      final bool canAuthenticateWithBiometrics = await _auth.canCheckBiometrics;
      final bool isSupported = await _auth.isDeviceSupported();
      return canAuthenticateWithBiometrics || isSupported;
    } on PlatformException catch (e) {
      print('Error checking biometrics support: $e');
      return false;
    }
  }

  /// Returns a list of enrolled biometric types (e.g., face, fingerprint, strong, weak)
  Future<List<BiometricType>> getAvailableBiometrics() async {
    try {
      return await _auth.getAvailableBiometrics();
    } on PlatformException catch (e) {
      print('Error getting available biometrics: $e');
      return <BiometricType>[];
    }
  }

  /// Prompts the user for biometric authentication.
  /// Enforces `biometricOnly: true` so it won't fallback to device PIN/Password.
  Future<Map<String, dynamic>> authenticate({String reason = 'Please authenticate to login securely'}) async {
    bool authenticated = false;
    String message = 'Authentication failed';

    try {
      authenticated = await _auth.authenticate(
        localizedReason: reason,
        biometricOnly: true,
        persistAcrossBackgrounding: true,
      );

      if (authenticated) {
        message = 'Authentication successful';
      } else {
        message = 'Authentication cancelled';
      }
    } on PlatformException catch (e) {
      authenticated = false;
      message = 'Biometric error: ${e.message}';
      print('Biometric auth error [${e.code}]: ${e.message}');
    }

    return {
      'success': authenticated,
      'message': message,
    };
  }
}
