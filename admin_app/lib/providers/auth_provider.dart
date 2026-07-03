import 'package:flutter/material.dart';
import '../models/user_model.dart';
import '../core/storage/storage_service.dart';
import '../core/network/api_client.dart';
import '../core/constants/api_constants.dart';

class AuthProvider extends ChangeNotifier {
  final StorageService _storage = StorageService();
  final ApiClient _apiClient = ApiClient();

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
      final response = await _apiClient.post(ApiConstants.login, {
        'email': email,
        'password': password,
      });
      
      final data = response['data'];
      final String token = data['token'];
      final userJson = data['user'];
      
      final user = UserModel.fromJson(userJson);
      
      if (user.role != 'ADMIN') {
        throw Exception('Access denied. Administrator privileges required.');
      }
      
      _user = user;
      await _storage.saveToken(token);
      await _storage.saveUser(user.id, user.email);
      
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

  Future<void> logout() async {
    try {
      await _apiClient.post(ApiConstants.logout, {});
    } catch (_) {}
    await _storage.clearAll();
    _user = null;
    notifyListeners();
  }

  Future<bool> tryAutoLogin() async {
    final token = _storage.getToken();
    if (token == null) return false;

    try {
      final response = await _apiClient.get('${ApiConstants.baseUrl}${ApiConstants.userDetail}/profile');
      final user = UserModel.fromJson(response['data']);
      
      if (user.role != 'ADMIN') {
        await _storage.clearAll();
        return false;
      }
      
      _user = user;
      notifyListeners();
      return true;
    } catch (_) {
      await _storage.clearAll();
      return false;
    }
  }
}
