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

  /**
   * DELETE /notifications/clear-all
   * Deletes ALL notifications for the currently authenticated user (user or admin).
   */
  async clearMyNotifications(req, res, next) {
    try {
      await notificationService.clearUserNotifications(req.user.id);
      return ApiResponse.success(res, 'All notifications cleared');
    } catch (error) {
      next(error);
    }
  }

  /**
   * DELETE /notifications/admin/clear-all
   * ADMIN-ONLY: Deletes every notification in the system for all users.
   */
  async clearAllNotifications(req, res, next) {
    try {
      await notificationService.clearAllNotifications();
      return ApiResponse.success(res, 'All notifications for all users have been cleared');
    } catch (error) {
      next(error);
    }
  }
}

module.exports = new NotificationController();
