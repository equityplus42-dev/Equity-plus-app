import 'package:flutter/material.dart';
import '../core/network/api_client.dart';
import '../core/constants/api_constants.dart';

class LanguageModel {
  final String id;
  final String name;
  final String code;
  final bool isDefault;
  final int videoCount;

  LanguageModel({
    required this.id,
    required this.name,
    required this.code,
    required this.isDefault,
    required this.videoCount,
  });

  factory LanguageModel.fromJson(Map<String, dynamic> json) {
    int vCount = 0;
    if (json['_count'] != null && json['_count']['videos'] != null) {
      vCount = json['_count']['videos'];
    }

    return LanguageModel(
      id: json['id'],
      name: json['name'],
      code: json['code'] ?? '',
      isDefault: json['isDefault'] ?? false,
      videoCount: vCount,
    );
  }
}

class AdminLanguagesProvider extends ChangeNotifier {
  final ApiClient _apiClient = ApiClient();

  List<LanguageModel> _languages = [];
  bool _isLoading = false;
  String? _errorMessage;

  List<LanguageModel> get languages => _languages;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  Future<void> fetchLanguages() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final response = await _apiClient.get(ApiConstants.languages);
      final List data = response['data'] ?? [];
      _languages = data.map((item) => LanguageModel.fromJson(item)).toList();
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _isLoading = false;
      _errorMessage = e.toString().replaceAll('Exception: ', '');
      notifyListeners();
    }
  }

  Future<bool> createLanguage(String name, String code) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      await _apiClient.post(ApiConstants.languages, {
        'name': name,
        'code': code,
      });
      await fetchLanguages();
      return true;
    } catch (e) {
      _isLoading = false;
      _errorMessage = e.toString().replaceAll('Exception: ', '');
      notifyListeners();
      return false;
    }
  }

  Future<bool> deleteLanguage(String id) async {
    try {
      await _apiClient.delete('${ApiConstants.languages}/$id');
      await fetchLanguages();
      return true;
    } catch (e) {
      _errorMessage = e.toString().replaceAll('Exception: ', '');
      notifyListeners();
      return false;
    }
  }
}
