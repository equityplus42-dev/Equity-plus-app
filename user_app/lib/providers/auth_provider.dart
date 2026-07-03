import 'package:flutter/material.dart';
import '../models/user_model.dart';
import '../repositories/auth_repository.dart';
import '../repositories/user_repository.dart';
import '../core/storage/storage_service.dart';

class AuthProvider extends ChangeNotifier {
  final AuthRepository _authRepository = AuthRepository();
  final UserRepository _userRepository = UserRepository();
  final StorageService _storage = StorageService();

  UserModel? _user;
  bool _isLoading = false;
  String? _errorMessage;

  UserModel? get user => _user;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  bool get isAuthenticated => _user != null;

  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }

  Future<bool> login(String email, String password) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      _user = await _authRepository.login(email, password);
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _isLoading = false;
      _errorMessage = e.toString().replaceAll('Exception: ', '');
      notifyListeners();
      return false;
    }
  }

  Future<bool> register({
    required String email,
    required String password,
    String? referralCode,
    String? firstName,
    String? lastName,
    String? phoneNumber,
  }) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      _user = await _authRepository.register(
        email: email,
        password: password,
        referralCode: referralCode,
        firstName: firstName,
        lastName: lastName,
        phoneNumber: phoneNumber,
      );
      _isLoading = false;
      notifyListeners();
      
      if (_user!.isApproved) {
        return true;
      } else {
        _user = null; // Clear user since they can't login yet
        return false;
      }
    } catch (e) {
      _isLoading = false;
      _errorMessage = e.toString().replaceAll('Exception: ', '');
      notifyListeners();
      return false;
    }
  }

  Future<void> logout() async {
    await _authRepository.logout();
    _user = null;
    notifyListeners();
  }

  Future<bool> tryAutoLogin() async {
    final token = _storage.getToken();
    if (token == null) return false;

    try {
      _user = await _userRepository.getProfile();
      notifyListeners();
      return true;
    } catch (_) {
      await _storage.clearAll();
      return false;
    }
  }

  // Reload user info (e.g. after updating profile or earning points)
  Future<void> refreshProfile() async {
    if (_user == null) return;
    try {
      _user = await _userRepository.getProfile();
      notifyListeners();
    } catch (_) {}
  }
}
