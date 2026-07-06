import 'package:flutter/material.dart';
import '../core/network/api_client.dart';
import '../core/constants/api_constants.dart';

class AdminSettingsProvider extends ChangeNotifier {
  final ApiClient _apiClient = ApiClient();

  Map<String, String> _settings = {};
  bool _isLoading = false;
  String? _errorMessage;

  Map<String, String> get settings => _settings;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  Future<void> fetchSettings() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final response = await _apiClient.get(ApiConstants.getSettings);
      final Map<String, dynamic> data = response['data'] ?? {};
      
      _settings = {};
      data.forEach((key, value) {
        _settings[key] = value.toString();
      });

      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _isLoading = false;
      _errorMessage = e.toString().replaceAll('Exception: ', '');
      notifyListeners();
    }
  }

  Future<bool> updateSetting(String key, String value, {String? description}) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final Map<String, dynamic> body = {
        'key': key,
        'value': value,
      };
      if (description != null) {
        body['description'] = description;
      }
      await _apiClient.put(ApiConstants.updateSetting, body);

      // Update local state map
      _settings[key] = value;
      
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _isLoading = false;
      _errorMessage = e.toString().replaceAll('Exception: ', '');
      notifyListeners();
      return false;
    }
  }
}
