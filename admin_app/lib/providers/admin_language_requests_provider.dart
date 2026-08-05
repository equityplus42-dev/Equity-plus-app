import 'package:flutter/material.dart';
import '../core/network/api_client.dart';
import '../core/constants/api_constants.dart';

class LanguageRequestModel {
  final String id;
  final String userId;
  final String userName;
  final String userEmail;
  final String currentLanguageName;
  final String requestedLanguageName;
  final String reason;
  final String status;
  final String? adminRemarks;
  final String requestedAt;

  LanguageRequestModel({
    required this.id,
    required this.userId,
    required this.userName,
    required this.userEmail,
    required this.currentLanguageName,
    required this.requestedLanguageName,
    required this.reason,
    required this.status,
    this.adminRemarks,
    required this.requestedAt,
  });

  factory LanguageRequestModel.fromJson(Map<String, dynamic> json) {
    String uName = 'User';
    String uEmail = '';
    if (json['user'] != null) {
      uEmail = json['user']['email'] ?? '';
      if (json['user']['profile'] != null) {
        final p = json['user']['profile'];
        uName = '${p['firstName'] ?? ''} ${p['lastName'] ?? ''}'.trim();
      }
    }
    if (uName.isEmpty) uName = uEmail;

    return LanguageRequestModel(
      id: json['id'],
      userId: json['userId'],
      userName: uName,
      userEmail: uEmail,
      currentLanguageName: json['currentLanguage'] != null ? json['currentLanguage']['name'] : 'Default',
      requestedLanguageName: json['requestedLanguage'] != null ? json['requestedLanguage']['name'] : 'Unknown',
      reason: json['reason'] ?? '',
      status: json['status'] ?? 'PENDING',
      adminRemarks: json['adminRemarks'],
      requestedAt: json['requestedAt'] ?? '',
    );
  }
}

class AdminLanguageRequestsProvider extends ChangeNotifier {
  final ApiClient _apiClient = ApiClient();

  List<LanguageRequestModel> _requests = [];
  bool _isLoading = false;
  String? _errorMessage;

  List<LanguageRequestModel> get requests => _requests;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  Future<void> fetchRequests({String status = 'PENDING'}) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final response = await _apiClient.get(
        ApiConstants.languageRequestsAdmin,
        queryParams: {'status': status},
      );
      final List data = response['data'] ?? [];
      _requests = data.map((item) => LanguageRequestModel.fromJson(item)).toList();
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _isLoading = false;
      _errorMessage = e.toString().replaceAll('Exception: ', '');
      notifyListeners();
    }
  }

  Future<bool> reviewRequest(
    String id, {
    required String status,
    String? adminRemarks,
    String resetProgressOption = 'OPTION_A',
  }) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      await _apiClient.patch(ApiConstants.reviewLanguageRequest(id), {
        'status': status,
        'adminRemarks': adminRemarks,
        'resetProgressOption': resetProgressOption,
      });
      await fetchRequests(status: 'PENDING');
      return true;
    } catch (e) {
      _isLoading = false;
      _errorMessage = e.toString().replaceAll('Exception: ', '');
      notifyListeners();
      return false;
    }
  }
}
