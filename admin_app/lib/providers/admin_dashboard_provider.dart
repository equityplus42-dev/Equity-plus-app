import 'package:flutter/material.dart';
import '../core/network/api_client.dart';
import '../core/constants/api_constants.dart';
import '../models/user_model.dart';

class AdminDashboardProvider extends ChangeNotifier {
  final ApiClient _apiClient = ApiClient();

  int _totalUsers = 0;
  int _pendingApprovals = 0;
  int _approvedReferrals = 0;
  int _totalReferrals = 0;
  int _totalPointsDistributed = 0;
  List<UserModel> _recentSignups = [];
  String? _referralCode;
  String? _qrCodeDataUrl;
  bool _isLoading = false;
  String? _errorMessage;

  int get totalUsers => _totalUsers;
  int get pendingApprovals => _pendingApprovals;
  int get approvedReferrals => _approvedReferrals;
  int get totalReferrals => _totalReferrals;
  int get totalPointsDistributed => _totalPointsDistributed;
  List<UserModel> get recentSignups => _recentSignups;
  String? get referralCode => _referralCode;
  String? get qrCodeDataUrl => _qrCodeDataUrl;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  Future<void> fetchDashboardStats() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final response = await _apiClient.get(ApiConstants.stats);
      final data = response['data'];
      
      _totalUsers = data['totalUsers'] ?? 0;
      _pendingApprovals = data['pendingApprovals'] ?? 0;
      _approvedReferrals = data['approvedReferrals'] ?? 0;
      _totalReferrals = data['totalReferrals'] ?? 0;
      _totalPointsDistributed = data['totalPointsDistributed'] ?? 0;

      final signupsList = data['recentSignups'] as List? ?? [];
      _recentSignups = signupsList.map((j) => UserModel.fromJson(j)).toList();

      try {
        final qrResponse = await _apiClient.get(ApiConstants.referralQR);
        if (qrResponse['success'] == true) {
          _qrCodeDataUrl = qrResponse['data']['qrCode'];
          _referralCode = qrResponse['data']['referralCode'];
        }
      } catch (qrError) {
        // Fallback silently if admin doesn't have a QR yet
        debugPrint('Could not fetch Admin QR: $qrError');
      }

      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _isLoading = false;
      _errorMessage = e.toString().replaceAll('Exception: ', '');
      notifyListeners();
    }
  }
}
