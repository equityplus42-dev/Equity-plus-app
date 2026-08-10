const videoAssignmentService = require('../services/videoAssignment.service');
const ApiResponse = require('../utils/apiResponse');

class VideoAssignmentController {
  async getDashboardStats(req, res, next) {
    try {
      const stats = await videoAssignmentService.getAssignmentDashboardStats();
      return ApiResponse.success(res, 'Assignment stats fetched successfully', stats);
    } catch (error) {
      next(error);
    }
  }

  async getVideoAssignments(req, res, next) {
    try {
      const { languageId, productId, search, page, limit } = req.query;
      const data = await videoAssignmentService.getVideoAssignments({ languageId, productId, search, page, limit });
      return ApiResponse.success(res, 'Video assignments fetched successfully', data);
    } catch (error) {
      next(error);
    }
  }

  async getVideoAssignmentDetails(req, res, next) {
    try {
      const { id } = req.params;
      const { search, page, limit } = req.query;
      const data = await videoAssignmentService.getVideoAssignmentDetails(id, { search, page, limit });
      return ApiResponse.success(res, 'Video assignment details fetched successfully', data);
    } catch (error) {
      next(error);
    }
  }

  async assignVideo(req, res, next) {
    try {
      const { userId, videoId } = req.body;
      const adminId = req.user.id;
      const result = await videoAssignmentService.assignVideoToUser({
        userId,
        videoId,
        adminId,
        reqIp: req.ip,
        userAgent: req.get('user-agent'),
      });
      return ApiResponse.success(res, 'Video assigned to user successfully', result, 201);
    } catch (error) {
      next(error);
    }
  }

  async bulkAssignVideo(req, res, next) {
    try {
      const { videoId, userIds } = req.body;
      const adminId = req.user.id;
      const result = await videoAssignmentService.bulkAssignVideo({
        videoId,
        userIds,
        adminId,
        reqIp: req.ip,
        userAgent: req.get('user-agent'),
      });
      return ApiResponse.success(res, 'Bulk video assignment processed successfully', result);
    } catch (error) {
      next(error);
    }
  }

  async unassignVideo(req, res, next) {
    try {
      const { id: videoId } = req.params;
      const { userId } = req.body;
      const adminId = req.user.id;
      const result = await videoAssignmentService.unassignVideoFromUser({
        userId,
        videoId,
        adminId,
        reqIp: req.ip,
        userAgent: req.get('user-agent'),
      });
      return ApiResponse.success(res, result.message, result);
    } catch (error) {
      next(error);
    }
  }

  async bulkUnassignVideo(req, res, next) {
    try {
      const { videoId, userIds } = req.body;
      const adminId = req.user.id;
      const result = await videoAssignmentService.bulkUnassignVideo({
        videoId,
        userIds,
        adminId,
        reqIp: req.ip,
        userAgent: req.get('user-agent'),
      });
      return ApiResponse.success(res, 'Bulk video unassignment processed successfully', result);
    } catch (error) {
      next(error);
    }
  }

  async getUserVideoAssignmentsAdmin(req, res, next) {
    try {
      const { id: userId } = req.params;
      const data = await videoAssignmentService.getUserVideoAssignmentsAdmin(userId);
      return ApiResponse.success(res, 'User video assignments fetched successfully', data);
    } catch (error) {
      next(error);
    }
  }
  async forceDeleteVideo(req, res, next) {
    try {
      const { id: videoId } = req.params;
      const adminId = req.user.id;
      const result = await videoAssignmentService.forceDeleteVideo({
        videoId,
        adminId,
        reqIp: req.ip,
        userAgent: req.get('user-agent'),
      });
      return ApiResponse.success(res, result.message, result);
    } catch (error) {
      next(error);
    }
  }
}

module.exports = new VideoAssignmentController();
