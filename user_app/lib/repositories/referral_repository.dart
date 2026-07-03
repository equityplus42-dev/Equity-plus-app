import '../core/network/api_client.dart';
import '../models/referral_model.dart';
import '../core/constants/api_constants.dart';

class ReferralRepository {
  final ApiClient _apiClient = ApiClient();

  Future<List<ReferralModel>> getReferrals() async {
    final response = await _apiClient.get(ApiConstants.referrals);
    final list = response['data'] as List? ?? [];
    return list.map((json) => ReferralModel.fromJson(json)).toList();
  }

  Future<Map<String, dynamic>> getStats() async {
    final response = await _apiClient.get(ApiConstants.referralStats);
    return response['data'] as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> getReferralQR() async {
    final response = await _apiClient.get(ApiConstants.referralQR);
    return response['data'] as Map<String, dynamic>;
  }
}
