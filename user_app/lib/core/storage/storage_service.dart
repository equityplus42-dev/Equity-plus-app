import 'package:shared_preferences/shared_preferences.dart';

class StorageService {
  static const String _keyToken = 'auth_token';
  static const String _keyUserId = 'user_id';
  static const String _keyUserEmail = 'user_email';

  static final StorageService _instance = StorageService._internal();
  factory StorageService() => _instance;
  StorageService._internal();

  late SharedPreferences _prefs;

  Future<void> init() async {
    _prefs = await SharedPreferences.getInstance();
  }

  // Token management
  Future<bool> saveToken(String token) async {
    return _prefs.setString(_keyToken, token);
  }

  String? getToken() {
    return _prefs.getString(_keyToken);
  }

  Future<bool> clearToken() async {
    return _prefs.remove(_keyToken);
  }

  // User info caching
  Future<void> saveUser(String id, String email) async {
    await _prefs.setString(_keyUserId, id);
    await _prefs.setString(_keyUserEmail, email);
  }

  String? getUserId() => _prefs.getString(_keyUserId);
  String? getUserEmail() => _prefs.getString(_keyUserEmail);

  Future<void> clearAll() async {
    // Retain biometric preferences and credentials on logout so they can log back in using biometrics.
    final biometricEnabled = _prefs.getBool('biometric_enabled') ?? false;
    final biometricEmail = _prefs.getString('biometric_email');
    final biometricPassword = _prefs.getString('biometric_password');

    await _prefs.clear();

    if (biometricEnabled) {
      await _prefs.setBool('biometric_enabled', true);
      if (biometricEmail != null) {
        await _prefs.setString('biometric_email', biometricEmail);
      }
      if (biometricPassword != null) {
        await _prefs.setString('biometric_password', biometricPassword);
      }
    }
  }
}
