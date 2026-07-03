import 'package:flutter/material.dart';
import '../repositories/referral_repository.dart';

class DashboardProvider extends ChangeNotifier {
  final ReferralRepository _referralRepository = ReferralRepository();

  int _totalReferrals = 0;
  int _approvedReferrals = 0;
  int _totalPoints = 0;
  String? _referralCode;
  String? _qrCodeDataUrl;
  bool _isLoading = false;
  String? _errorMessage;

  int get totalReferrals => _totalReferrals;
  int get approvedReferrals => _approvedReferrals;
  int get totalPoints => _totalPoints;
  String? get referralCode => _referralCode;
  String? get qrCodeDataUrl => _qrCodeDataUrl;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  Future<void> fetchDashboardData() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      // 1. Fetch Stats
      final stats = await _referralRepository.getStats();
      _totalReferrals = stats['totalReferrals'] ?? 0;
      _approvedReferrals = stats['approvedReferrals'] ?? 0;
      _totalPoints = stats['totalPoints'] ?? 0;

      // 2. Fetch QR
      final qrInfo = await _referralRepository.getReferralQR();
      _qrCodeDataUrl = qrInfo['qrCode'];
      _referralCode = qrInfo['referralCode'];

      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _isLoading = false;
      _errorMessage = e.toString().replaceAll('Exception: ', '');
      notifyListeners();
    }
  }
}
