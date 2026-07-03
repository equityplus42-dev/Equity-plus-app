const notificationService = require('../services/notification.service');
const ApiResponse = require('../utils/apiResponse');

class NotificationController {
  async getNotifications(req, res, next) {
    try {
      const list = await notificationService.getUserNotifications(req.user.id);
      return ApiResponse.success(res, 'Notifications retrieved', list);
    } catch (error) {
      next(error);
    }
  }

  async markAsRead(req, res, next) {
    try {
      const updated = await notificationService.markAsRead(req.params.id);
      return ApiResponse.success(res, 'Notification marked as read', updated);
    } catch (error) {
      next(error);
    }
  }

  async markAllRead(req, res, next) {
    try {
      await notificationService.markAllRead(req.user.id);
      return ApiResponse.success(res, 'All notifications marked as read');
    } catch (error) {
      next(error);
    }
  }
}

module.exports = new NotificationController();
