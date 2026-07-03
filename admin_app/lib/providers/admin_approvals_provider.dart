import 'package:flutter/material.dart';
import '../core/network/api_client.dart';
import '../core/constants/api_constants.dart';
import '../models/referral_model.dart';

class AdminApprovalsProvider extends ChangeNotifier {
  final ApiClient _apiClient = ApiClient();

  List<ReferralModel> _pendingReferrals = [];
  bool _isLoading = false;
  String? _errorMessage;

  List<ReferralModel> get pendingReferrals => _pendingReferrals;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  Future<void> fetchPendingApprovals() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final response = await _apiClient.get(ApiConstants.pendingReferrals);
      final list = response['data'] as List? ?? [];
      _pendingReferrals = list.map((j) => ReferralModel.fromJson(j)).toList();
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _isLoading = false;
      _errorMessage = e.toString().replaceAll('Exception: ', '');
      notifyListeners();
    }
  }

  Future<bool> approveReferral(String referralId) async {
    try {
      await _apiClient.patch(ApiConstants.approveReferral(referralId), {});
      _pendingReferrals.removeWhere((r) => r.id == referralId);
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = e.toString().replaceAll('Exception: ', '');
      notifyListeners();
      return false;
    }
  }

  Future<bool> rejectReferral(String referralId) async {
    try {
      await _apiClient.patch(ApiConstants.rejectReferral(referralId), {});
      _pendingReferrals.removeWhere((r) => r.id == referralId);
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = e.toString().replaceAll('Exception: ', '');
      notifyListeners();
      return false;
    }
  }
}
