import 'package:flutter/material.dart';
import '../models/hierarchy_model.dart';
import '../repositories/hierarchy_repository.dart';

class HierarchyProvider extends ChangeNotifier {
  final HierarchyRepository _hierarchyRepository = HierarchyRepository();

  List<HierarchyNodeModel> _hierarchyTree = [];
  bool _isLoading = false;
  String? _errorMessage;

  List<HierarchyNodeModel> get hierarchyTree => _hierarchyTree;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  Future<void> fetchHierarchy({int? depth}) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      _hierarchyTree = await _hierarchyRepository.getUserHierarchy(depth: depth);
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _isLoading = false;
      _errorMessage = e.toString().replaceAll('Exception: ', '');
      notifyListeners();
    }
  }
}
