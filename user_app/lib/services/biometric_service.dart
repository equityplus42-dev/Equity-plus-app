import 'package:flutter/foundation.dart';
import 'package:local_auth/local_auth.dart';

class BiometricService {
  final LocalAuthentication _auth = LocalAuthentication();

  /// Checks if the device supports biometric authentication and if any are enrolled.
  Future<bool> canAuthenticate() async {
    if (kIsWeb) return false;
    try {
      final bool canAuthenticateWithBiometrics = await _auth.canCheckBiometrics;
      final bool isSupported = await _auth.isDeviceSupported();
      return canAuthenticateWithBiometrics || isSupported;
    } catch (e) {
      debugPrint('Error checking biometrics support: $e');
      return false;
    }
  }

  /// Returns a list of enrolled biometric types (e.g., face, fingerprint, strong, weak)
  Future<List<BiometricType>> getAvailableBiometrics() async {
    if (kIsWeb) return <BiometricType>[];
    try {
      return await _auth.getAvailableBiometrics();
    } catch (e) {
      debugPrint('Error getting available biometrics: $e');
      return <BiometricType>[];
    }
  }

  /// Prompts the user for biometric authentication.
  /// Enforces `biometricOnly: true` so it won't fallback to device PIN/Password.
  Future<Map<String, dynamic>> authenticate({String reason = 'Please authenticate to login securely'}) async {
    if (kIsWeb) {
      return {'success': false, 'message': 'Biometric authentication is not supported on web.'};
    }
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
    } catch (e) {
      authenticated = false;
      message = 'Biometric error: $e';
      debugPrint('Biometric auth error: $e');
    }

    return {
      'success': authenticated,
      'message': message,
    };
  }
}

