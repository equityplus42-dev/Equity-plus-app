const announcementService = require('../services/announcement.service');
const ApiResponse = require('../utils/apiResponse');

class AnnouncementController {
  async createAnnouncement(req, res, next) {
    try {
      const { title, message, targetType, targetId, scheduledAt } = req.body;
      const announcement = await announcementService.createAnnouncement({
        title,
        message,
        targetType,
        targetId,
        scheduledAt,
        createdById: req.user.id,
      });
      return ApiResponse.success(res, 'Announcement created & broadcasted', announcement, 201);
    } catch (error) {
      next(error);
    }
  }

  async getAdminAnnouncements(req, res, next) {
    try {
      const list = await announcementService.getAdminAnnouncements();
      return ApiResponse.success(res, 'Admin announcements fetched', list);
    } catch (error) {
      next(error);
    }
  }

  async getUserAnnouncements(req, res, next) {
    try {
      const list = await announcementService.getUserAnnouncements(req.user.id);
      return ApiResponse.success(res, 'User announcements fetched', list);
    } catch (error) {
      next(error);
    }
  }
}

module.exports = new AnnouncementController();
