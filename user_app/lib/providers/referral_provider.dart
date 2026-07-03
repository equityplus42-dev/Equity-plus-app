import 'package:flutter/material.dart';
import '../models/referral_model.dart';
import '../repositories/referral_repository.dart';

class ReferralProvider extends ChangeNotifier {
  final ReferralRepository _referralRepository = ReferralRepository();

  List<ReferralModel> _referrals = [];
  bool _isLoading = false;
  String? _errorMessage;

  List<ReferralModel> get referrals => _referrals;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  Future<void> fetchReferrals() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      _referrals = await _referralRepository.getReferrals();
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _isLoading = false;
      _errorMessage = e.toString().replaceAll('Exception: ', '');
      notifyListeners();
    }
  }
}
