import 'package:flutter/material.dart';
import '../core/network/api_client.dart';
import '../core/constants/api_constants.dart';
import '../models/hierarchy_model.dart';

class AdminHierarchyProvider extends ChangeNotifier {
  final ApiClient _apiClient = ApiClient();

  List<HierarchyNodeModel> _globalTree = [];
  bool _isLoading = false;
  String? _errorMessage;

  List<HierarchyNodeModel> get globalTree => _globalTree;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  Future<void> fetchGlobalHierarchy() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final response = await _apiClient.get('${ApiConstants.hierarchy}/global');
      final list = response['data'] as List? ?? [];
      _globalTree = list.map((json) => HierarchyNodeModel.fromJson(json)).toList();
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _isLoading = false;
      _errorMessage = e.toString().replaceAll('Exception: ', '');
      notifyListeners();
    }
  }
}
