const videoAnalyticsService = require('../services/videoAnalytics.service');
const ApiResponse = require('../utils/apiResponse');

class VideoAnalyticsController {
  async getVideoAnalytics(req, res, next) {
    try {
      const { videoId } = req.params;
      const analytics = await videoAnalyticsService.getVideoAnalytics(videoId);
      return ApiResponse.success(res, 'Video analytics fetched', analytics);
    } catch (error) {
      next(error);
    }
  }

  async getGlobalAnalytics(req, res, next) {
    try {
      const analytics = await videoAnalyticsService.getGlobalVideoAnalytics();
      return ApiResponse.success(res, 'Global analytics fetched', analytics);
    } catch (error) {
      next(error);
    }
  }
}

module.exports = new VideoAnalyticsController();
