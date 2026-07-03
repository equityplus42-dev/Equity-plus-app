import '../core/network/api_client.dart';
import '../models/user_model.dart';
import '../core/constants/api_constants.dart';

class UserRepository {
  final ApiClient _apiClient = ApiClient();

  Future<UserModel> getProfile() async {
    final response = await _apiClient.get(ApiConstants.profile);
    return UserModel.fromJson(response['data']);
  }
}
