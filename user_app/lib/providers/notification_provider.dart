import 'package:flutter/material.dart';
import '../models/notification_model.dart';
import '../repositories/notification_repository.dart';
import '../services/local_notification_service.dart';

class NotificationProvider extends ChangeNotifier {
  final NotificationRepository _notificationRepository = NotificationRepository();

  List<NotificationModel> _notifications = [];
  bool _isLoading = false;
  String? _errorMessage;
  final Set<String> _poppedNotificationIds = {};
  bool _isFirstFetch = true;

  List<NotificationModel> get notifications => _notifications;
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
      final fetched = await _notificationRepository.getNotifications();
      
      // Trigger native system shade notifications for new unread notifications
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
        // Record initial unread notification IDs so past notifications don't spam popups on launch
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

  Future<void> markAsRead(String id) async {
    try {
      await _notificationRepository.markAsRead(id);
      
      // Update local state
      final index = _notifications.indexWhere((n) => n.id == id);
      if (index != -1) {
        final old = _notifications[index];
        _notifications[index] = NotificationModel(
          id: old.id,
          userId: old.userId,
          title: old.title,
          message: old.message,
          isRead: true,
          type: old.type,
          createdAt: old.createdAt,
        );
        notifyListeners();
      }
    } catch (_) {}
  }

  Future<void> markAllAsRead() async {
    try {
      await _notificationRepository.markAllAsRead();
      
      // Update all local state to read
      _notifications = _notifications.map((n) {
        return NotificationModel(
          id: n.id,
          userId: n.userId,
          title: n.title,
          message: n.message,
          isRead: true,
          type: n.type,
          createdAt: n.createdAt,
        );
      }).toList();
      notifyListeners();
    } catch (_) {}
  }

  Future<bool> clearAll() async {
    try {
      await _notificationRepository.clearAll();
      // Immediately clear local list so the badge & list update without waiting
      _notifications = [];
      notifyListeners();
      // Then re-sync with server to confirm empty state
      await fetchNotifications();
      return true;
    } catch (e) {
      _errorMessage = e.toString().replaceAll('Exception: ', '');
      notifyListeners();
      return false;
    }
  }
}
