import 'package:flutter/material.dart';
import '../repositories/referral_repository.dart';
import '../core/network/api_client.dart';

class DashboardProvider extends ChangeNotifier {
  final ReferralRepository _referralRepository = ReferralRepository();

  int _totalReferrals = 0;
  int _approvedReferrals = 0;
  int _totalPoints = 0;
  String? _referralCode;
  String? _qrCodeDataUrl;
  Map<String, String> _systemSettings = {};
  bool _isLoading = false;
  String? _errorMessage;

  int get totalReferrals => _totalReferrals;
  int get approvedReferrals => _approvedReferrals;
  int get totalPoints => _totalPoints;
  String? get referralCode => _referralCode;
  String? get qrCodeDataUrl => _qrCodeDataUrl;
  Map<String, String> get systemSettings => _systemSettings;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  Future<void> fetchDashboardData({bool silent = false}) async {
    if (!silent && _totalReferrals == 0 && _referralCode == null) {
      _isLoading = true;
      _errorMessage = null;
      notifyListeners();
    }

    try {
      // 1. Fetch Stats
      final stats = await _referralRepository.getStats();
      _totalReferrals = stats['totalReferrals'] ?? 0;
      _approvedReferrals = stats['approvedReferrals'] ?? 0;
      _totalPoints = stats['totalPoints'] ?? 0;

      // 2. Fetch QR
      if (_referralCode == null) {
        final qrInfo = await _referralRepository.getReferralQR();
        _qrCodeDataUrl = qrInfo['qrCode'];
        _referralCode = qrInfo['referralCode'];
      }

      // 3. Fetch Settings
      try {
        final settingsResponse = await ApiClient().get('/settings');
        final Map<String, dynamic> settingsData = settingsResponse['data'] ?? {};
        _systemSettings = {};
        settingsData.forEach((key, value) {
          _systemSettings[key] = value.toString();
        });
      } catch (e) {
        debugPrint('Failed to load system settings in user_app: $e');
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
