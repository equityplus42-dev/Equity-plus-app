const videoVersionService = require('../services/videoVersion.service');
const ApiResponse = require('../utils/apiResponse');

class VideoVersionController {
  async createVersion(req, res, next) {
    try {
      const { videoId } = req.params;
      const { title, description, videoUrl, thumbnailUrl, duration, changeLog } = req.body;
      const version = await videoVersionService.createVersion(videoId, {
        title,
        description,
        videoUrl,
        thumbnailUrl,
        duration,
        changeLog,
        createdBy: req.user.id,
      });
      return ApiResponse.success(res, 'New video version created', version, 201);
    } catch (error) {
      next(error);
    }
  }

  async getVersionHistory(req, res, next) {
    try {
      const { videoId } = req.params;
      const history = await videoVersionService.getVersionHistory(videoId);
      return ApiResponse.success(res, 'Video version history fetched', history);
    } catch (error) {
      next(error);
    }
  }

  async restoreVersion(req, res, next) {
    try {
      const { videoId, versionId } = req.params;
      const restored = await videoVersionService.restoreVersion(videoId, versionId);
      return ApiResponse.success(res, 'Video version restored successfully', restored);
    } catch (error) {
      next(error);
    }
  }
}

module.exports = new VideoVersionController();
