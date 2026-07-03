import '../core/network/api_client.dart';
import '../core/storage/storage_service.dart';
import '../models/user_model.dart';
import '../core/constants/api_constants.dart';

class AuthRepository {
  final ApiClient _apiClient = ApiClient();
  final StorageService _storage = StorageService();

  Future<UserModel> login(String email, String password) async {
    final response = await _apiClient.post(ApiConstants.login, {
      'email': email,
      'password': password,
    });
    
    final data = response['data'];
    final String token = data['token'];
    final userJson = data['user'];
    
    final user = UserModel.fromJson(userJson);
    
    // Save token and info
    await _storage.saveToken(token);
    await _storage.saveUser(user.id, user.email);
    
    return user;
  }

  Future<UserModel> register({
    required String email,
    required String password,
    String? referralCode,
    String? firstName,
    String? lastName,
    String? phoneNumber,
  }) async {
    final response = await _apiClient.post(ApiConstants.register, {
      'email': email,
      'password': password,
      if (referralCode != null && referralCode.isNotEmpty) 'referralCode': referralCode,
      if (firstName != null && firstName.isNotEmpty) 'firstName': firstName,
      if (lastName != null && lastName.isNotEmpty) 'lastName': lastName,
      if (phoneNumber != null && phoneNumber.isNotEmpty) 'phoneNumber': phoneNumber,
    });
    
    final data = response['data'];
    final String token = data['token'];
    final userJson = data['user'];
    
    final user = UserModel.fromJson(userJson);
    
    // Save token and info
    await _storage.saveToken(token);
    await _storage.saveUser(user.id, user.email);
    
    return user;
  }

  Future<void> logout() async {
    try {
      await _apiClient.post(ApiConstants.logout, {});
    } catch (_) {}
    await _storage.clearAll();
  }
}
