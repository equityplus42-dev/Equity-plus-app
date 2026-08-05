import 'package:flutter/material.dart';
import '../core/network/api_client.dart';
import '../core/constants/api_constants.dart';

class ProductModel {
  final String id;
  final String name;
  final String code;
  final String? description;
  final String status;
  final int videoCount;

  ProductModel({
    required this.id,
    required this.name,
    required this.code,
    this.description,
    required this.status,
    required this.videoCount,
  });

  factory ProductModel.fromJson(Map<String, dynamic> json) {
    int vCount = 0;
    if (json['_count'] != null && json['_count']['videos'] != null) {
      vCount = json['_count']['videos'];
    }

    return ProductModel(
      id: json['id'],
      name: json['name'],
      code: json['code'] ?? '',
      description: json['description'],
      status: json['status'] ?? 'AVAILABLE',
      videoCount: vCount,
    );
  }
}

class AdminProductsProvider extends ChangeNotifier {
  final ApiClient _apiClient = ApiClient();

  List<ProductModel> _products = [];
  bool _isLoading = false;
  String? _errorMessage;

  List<ProductModel> get products => _products;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  Future<void> fetchProducts({String status = 'ALL'}) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final response = await _apiClient.get(
        ApiConstants.productsAdmin,
        queryParams: {'status': status},
      );
      final List data = response['data'] ?? [];
      _products = data.map((item) => ProductModel.fromJson(item)).toList();
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _isLoading = false;
      _errorMessage = e.toString().replaceAll('Exception: ', '');
      notifyListeners();
    }
  }

  Future<bool> createProduct({
    required String name,
    required String code,
    String? description,
  }) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      await _apiClient.post(ApiConstants.productsAdmin, {
        'name': name,
        'code': code,
        'description': description,
      });
      await fetchProducts();
      return true;
    } catch (e) {
      _isLoading = false;
      _errorMessage = e.toString().replaceAll('Exception: ', '');
      notifyListeners();
      return false;
    }
  }

  Future<bool> archiveProduct(String id) async {
    try {
      await _apiClient.patch(ApiConstants.archiveProduct(id), {});
      await fetchProducts();
      return true;
    } catch (e) {
      _errorMessage = e.toString().replaceAll('Exception: ', '');
      notifyListeners();
      return false;
    }
  }

  Future<bool> assignUserProduct(String userId, String? productId) async {
    try {
      await _apiClient.put(ApiConstants.assignUserProduct(userId), {
        'productId': productId,
      });
      return true;
    } catch (e) {
      _errorMessage = e.toString().replaceAll('Exception: ', '');
      notifyListeners();
      return false;
    }
  }
}
