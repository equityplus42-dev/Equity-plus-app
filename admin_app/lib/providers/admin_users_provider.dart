import 'package:flutter/material.dart';
import '../core/network/api_client.dart';
import '../core/constants/api_constants.dart';
import '../models/user_model.dart';

class AdminUsersProvider extends ChangeNotifier {
  final ApiClient _apiClient = ApiClient();

  List<UserModel> _users = [];
  bool _isLoading = false;
  String? _errorMessage;
  int _currentPage = 1;
  bool _hasNext = false;

  List<UserModel> get users => _users;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  int get currentPage => _currentPage;
  bool get hasNext => _hasNext;

  Future<void> fetchUsers({String search = '', bool refresh = false}) async {
    if (refresh) {
      _currentPage = 1;
      _users = [];
    }

    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final Map<String, String> queryParams = {
        'page': _currentPage.toString(),
        'limit': '15',
      };
      if (search.isNotEmpty) {
        queryParams['search'] = search;
      }

      final response = await _apiClient.get(ApiConstants.users, queryParams: queryParams);
      final data = response['data'];
      
      final list = data['items'] as List? ?? [];
      final List<UserModel> fetched = list.map((j) => UserModel.fromJson(j)).toList();

      if (refresh) {
        _users = fetched;
      } else {
        _users.addAll(fetched);
      }

      final pagination = data['pagination'];
      _hasNext = pagination['hasNext'] ?? false;
      
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _isLoading = false;
      _errorMessage = e.toString().replaceAll('Exception: ', '');
      notifyListeners();
    }
  }

  void loadNextPage({String search = ''}) {
    if (_hasNext && !_isLoading) {
      _currentPage++;
      fetchUsers(search: search);
    }
  }

  Future<bool> toggleUserApproval(String userId, bool isActive) async {
    try {
      await _apiClient.patch(ApiConstants.toggleUserApproval(userId), {
        'isActive': isActive,
      });

      // Update local state list
      final index = _users.indexWhere((u) => u.id == userId);
      if (index != -1) {
        final old = _users[index];
        _users[index] = UserModel(
          id: old.id,
          email: old.email,
          role: old.role,
          referralCode: old.referralCode,
          referrerId: old.referrerId,
          points: old.points,
          isApproved: old.isApproved,
          isActive: isActive,
          createdAt: old.createdAt,
          firstName: old.firstName,
          lastName: old.lastName,
          phoneNumber: old.phoneNumber,
          avatarUrl: old.avatarUrl,
          bio: old.bio,
        );
        notifyListeners();
      }
      return true;
    } catch (e) {
      _errorMessage = e.toString().replaceAll('Exception: ', '');
      notifyListeners();
      return false;
    }
  }

  Future<bool> deleteUser(String userId) async {
    try {
      await _apiClient.delete('${ApiConstants.users}/$userId');
      _users.removeWhere((u) => u.id == userId);
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = e.toString().replaceAll('Exception: ', '');
      notifyListeners();
      return false;
    }
  }
}
