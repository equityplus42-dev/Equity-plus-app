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
      'firstName': ?firstName,
      'lastName': ?lastName,
      'phoneNumber': ?phoneNumber,
      'bio': ?bio,
    });
    return response['data'];
  }

  Future<Map<String, dynamic>> uploadAvatar(Uint8List bytes, String fileName) async {
    final response = await _apiClient.uploadAvatar(bytes, fileName);
    return response['data'];
  }
}
