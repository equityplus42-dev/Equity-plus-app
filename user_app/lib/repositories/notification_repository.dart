import '../core/network/api_client.dart';
import '../models/notification_model.dart';
import '../core/constants/api_constants.dart';

class NotificationRepository {
  final ApiClient _apiClient = ApiClient();

  Future<List<NotificationModel>> getNotifications() async {
    final response = await _apiClient.get(ApiConstants.notifications);
    final list = response['data'] as List? ?? [];
    return list.map((json) => NotificationModel.fromJson(json)).toList();
  }

  Future<void> markAsRead(String id) async {
    await _apiClient.patch(ApiConstants.readNotification(id), {});
  }

  Future<void> markAllAsRead() async {
    await _apiClient.patch(ApiConstants.readAllNotifications, {});
  }
}
