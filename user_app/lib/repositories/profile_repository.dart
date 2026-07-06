import 'dart:typed_data';
import '../core/network/api_client.dart';
import '../core/constants/api_constants.dart';

class ProfileRepository {
  final ApiClient _apiClient = ApiClient();

  Future<Map<String, dynamic>> updateProfile({
    String? firstName,
    String? lastName,
    String? phoneNumber,
    String? whatsApp,
    String? state,
    String? district,
    String? bio,
    String? panNumber,
    String? aadharNumber,
  }) async {
    final Map<String, dynamic> body = {};
    if (firstName != null) body['firstName'] = firstName;
    if (lastName != null) body['lastName'] = lastName;
    if (phoneNumber != null) body['phoneNumber'] = phoneNumber;
    if (whatsApp != null) body['whatsApp'] = whatsApp;
    if (state != null) body['state'] = state;
    if (district != null) body['district'] = district;
    if (bio != null) body['bio'] = bio;
    if (panNumber != null) body['panNumber'] = panNumber;
    if (aadharNumber != null) body['aadharNumber'] = aadharNumber;

    final response = await _apiClient.put(ApiConstants.updateProfile, body);
    return response['data'];
  }

  Future<Map<String, dynamic>> uploadAvatar(Uint8List bytes, String fileName) async {
    final response = await _apiClient.uploadAvatar(bytes, fileName);
    return response['data'];
  }
}
