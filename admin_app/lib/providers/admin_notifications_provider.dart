import 'package:flutter/material.dart';
import '../core/network/api_client.dart';
import '../services/local_notification_service.dart';

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
  final Set<String> _poppedNotificationIds = {};
  bool _isFirstFetch = true;

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
      final fetched = list.map((item) => AdminNotificationModel.fromJson(item)).toList();

      // Trigger native mobile system notifications for new unread admin alerts
      for (final n in fetched) {
        if (!n.isRead && !_poppedNotificationIds.contains(n.id)) {
          if (!_isFirstFetch) {
            LocalNotificationService().showNotification(
              id: n.id.hashCode,
              title: n.title,
              body: n.message,
            );
          }
          _poppedNotificationIds.add(n.id);
        }
      }

      if (_isFirstFetch) {
        // Record initial unread notification IDs on app startup
        for (final n in fetched) {
          _poppedNotificationIds.add(n.id);
        }
        _isFirstFetch = false;
      }

      _notifications = fetched;
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
      // Immediately clear local list so UI updates without waiting
      _notifications = [];
      notifyListeners();
      // Then re-sync with server to confirm empty state
      await fetchNotifications(silent: true);
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
      // Immediately clear local list so UI updates without waiting
      _notifications = [];
      notifyListeners();
      // Then re-sync with server to confirm empty state
      await fetchNotifications(silent: true);
      return true;
    } catch (e) {
      _errorMessage = e.toString().replaceAll('Exception: ', '');
      notifyListeners();
      return false;
    }
  }
}
