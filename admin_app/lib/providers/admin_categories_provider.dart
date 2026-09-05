import 'package:flutter/material.dart';
import '../core/network/api_client.dart';
import '../core/constants/api_constants.dart';

class CategoryModel {
  final String id;
  final String name;
  final String? description;
  final int orderIndex;
  final int videoCount;

  CategoryModel({
    required this.id,
    required this.name,
    this.description,
    required this.orderIndex,
    required this.videoCount,
  });

  factory CategoryModel.fromJson(Map<String, dynamic> json) {
    return CategoryModel(
      id: json['id'],
      name: json['name'],
      description: json['description'],
      orderIndex: json['orderIndex'] ?? 0,
      videoCount: json['videoCount'] ?? 0,
    );
  }
}

class AdminCategoriesProvider extends ChangeNotifier {
  final ApiClient _apiClient = ApiClient();

  List<CategoryModel> _categories = [];
  bool _isLoading = false;
  String? _errorMessage;

  List<CategoryModel> get categories => _categories;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  Future<void> fetchCategories() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final response = await _apiClient.get(ApiConstants.categories);
      final List data = response['data'] ?? [];
      _categories = data.map((item) => CategoryModel.fromJson(item)).toList();
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _isLoading = false;
      _errorMessage = e.toString().replaceAll('Exception: ', '');
      notifyListeners();
    }
  }

  Future<bool> createCategory(String name, String? description) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      await _apiClient.post(ApiConstants.categories, {
        'name': name,
        if (description != null && description.isNotEmpty) 'description': description,
      });
      await fetchCategories();
      return true;
    } catch (e) {
      _isLoading = false;
      _errorMessage = e.toString().replaceAll('Exception: ', '');
      notifyListeners();
      return false;
    }
  }

  Future<bool> deleteCategory(String id) async {
    try {
      _categories.removeWhere((c) => c.id == id);
      notifyListeners();

      await _apiClient.delete('${ApiConstants.categories}/$id');
      await fetchCategories();
      return true;
    } catch (e) {
      _errorMessage = e.toString().replaceAll('Exception: ', '');
      await fetchCategories();
      notifyListeners();
      return false;
    }
  }
}
