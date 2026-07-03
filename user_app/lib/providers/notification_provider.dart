import 'package:flutter/material.dart';
import '../models/notification_model.dart';
import '../repositories/notification_repository.dart';

class NotificationProvider extends ChangeNotifier {
  final NotificationRepository _notificationRepository = NotificationRepository();

  List<NotificationModel> _notifications = [];
  bool _isLoading = false;
  String? _errorMessage;

  List<NotificationModel> get notifications => _notifications;
  int get unreadCount => _notifications.where((n) => !n.isRead).length;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  Future<void> fetchNotifications() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      _notifications = await _notificationRepository.getNotifications();
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
}
