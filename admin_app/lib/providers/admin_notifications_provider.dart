import 'package:flutter/material.dart';
import '../core/network/api_client.dart';

class AdminNotificationModel {
  final String id;
  final String title;
  final String message;
  final String type;
  final bool isRead;
  final DateTime createdAt;

  AdminNotificationModel({
    required this.id,
    required this.title,
    required this.message,
    required this.type,
    required this.isRead,
    required this.createdAt,
  });

  factory AdminNotificationModel.fromJson(Map<String, dynamic> json) {
    return AdminNotificationModel(
      id: json['id'] ?? '',
      title: json['title'] ?? '',
      message: json['message'] ?? '',
      type: json['type'] ?? 'SYSTEM',
      isRead: json['isRead'] ?? false,
      createdAt: json['createdAt'] != null
          ? DateTime.parse(json['createdAt'])
          : DateTime.now(),
    );
  }
}

class AdminNotificationsProvider extends ChangeNotifier {
  final ApiClient _apiClient = ApiClient();

  List<AdminNotificationModel> _notifications = [];
  bool _isLoading = false;
  String? _errorMessage;

  List<AdminNotificationModel> get notifications => _notifications;
  int get unreadCount => _notifications.where((n) => !n.isRead).length;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  Future<void> fetchNotifications({bool silent = false}) async {
    if (!silent) {
      _isLoading = true;
      _errorMessage = null;
      notifyListeners();
    }

    try {
      final res = await _apiClient.get('/notifications');
      final List list = res['data'] ?? [];
      _notifications = list.map((item) => AdminNotificationModel.fromJson(item)).toList();
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _isLoading = false;
      _errorMessage = e.toString().replaceAll('Exception: ', '');
      notifyListeners();
    }
  }

  Future<void> markAllRead() async {
    try {
      await _apiClient.patch('/notifications/read-all', {});
      await fetchNotifications(silent: true);
    } catch (e) {
      debugPrint('Error marking all notifications read: $e');
    }
  }

  Future<void> markAsRead(String id) async {
    try {
      await _apiClient.patch('/notifications/$id/read', {});
      await fetchNotifications(silent: true);
    } catch (e) {
      debugPrint('Error marking notification read: $e');
    }
  }

  Future<bool> approveCashPayment(String paymentId) async {
    try {
      await _apiClient.post('/payments/approve-cash/$paymentId', {});
      await fetchNotifications(silent: true);
      return true;
    } catch (e) {
      _errorMessage = e.toString().replaceAll('Exception: ', '');
      notifyListeners();
      return false;
    }
  }

  /// Clears only this admin's own notifications (DELETE /notifications/clear-all)
  Future<bool> clearMyNotifications() async {
    try {
      await _apiClient.delete('/notifications/clear-all');
      _notifications = [];
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = e.toString().replaceAll('Exception: ', '');
      notifyListeners();
      return false;
    }
  }

  /// Admin superpower: clears EVERY user's notifications (DELETE /notifications/admin/clear-all)
  Future<bool> clearAllUsersNotifications() async {
    try {
      await _apiClient.delete('/notifications/admin/clear-all');
      _notifications = [];
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = e.toString().replaceAll('Exception: ', '');
      notifyListeners();
      return false;
    }
  }
}
