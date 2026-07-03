import 'dart:typed_data';
import '../core/network/api_client.dart';
import '../core/constants/api_constants.dart';

class ProfileRepository {
  final ApiClient _apiClient = ApiClient();

  Future<Map<String, dynamic>> updateProfile({
    String? firstName,
    String? lastName,
    String? phoneNumber,
    String? bio,
  }) async {
    final response = await _apiClient.put(ApiConstants.updateProfile, {
      if (firstName != null) 'firstName': firstName,
      if (lastName != null) 'lastName': lastName,
      if (phoneNumber != null) 'phoneNumber': phoneNumber,
      if (bio != null) 'bio': bio,
    });
    return response['data'];
  }

  Future<Map<String, dynamic>> uploadAvatar(Uint8List bytes, String fileName) async {
    final response = await _apiClient.uploadAvatar(bytes, fileName);
    return response['data'];
  }
}
