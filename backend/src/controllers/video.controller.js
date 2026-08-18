const videoService = require('../services/video.service');
const ApiResponse = require('../utils/apiResponse');

class VideoController {
  async createVideo(req, res, next) {
    try {
      const { title, description, videoUrl, thumbnailUrl, duration, languageId, productId, status, orderIndex, r2ObjectKey, provider } = req.body;
      if (!title || !videoUrl || !languageId) {
        return ApiResponse.error(res, 'Title, videoUrl, and languageId are required', 400);
      }
      const video = await videoService.createVideo({
        title,
        description,
        videoUrl,
        thumbnailUrl,
        duration,
        languageId,
        productId,
        status,
        orderIndex,
        r2ObjectKey,
        provider,
      });
      return ApiResponse.success(res, 'Video created successfully', video, 201);
    } catch (error) {
      next(error);
    }
  }

  async getAllVideosAdmin(req, res, next) {
    try {
      const { languageId, includeArchived } = req.query;
      const videos = await videoService.getAllVideosAdmin(languageId, includeArchived === 'true');
      return ApiResponse.success(res, 'Admin videos fetched successfully', videos);
    } catch (error) {
      next(error);
    }
  }

  async deleteVideo(req, res, next) {
    try {
      const { id } = req.params;
      await videoService.deleteVideo(id);
      return ApiResponse.success(res, 'Video deleted successfully');
    } catch (error) {
      next(error);
    }
  }

  async reorderVideos(req, res, next) {
    try {
      const { videoOrders } = req.body;
      const result = await videoService.reorderVideos(videoOrders);
      return ApiResponse.success(res, result.message);
    } catch (error) {
      next(error);
    }
  }

  async assignUserLanguage(req, res, next) {
    try {
      const { id } = req.params;
      const { languageId } = req.body;
      if (!languageId) {
        return ApiResponse.error(res, 'languageId is required', 400);
      }
      const result = await videoService.assignUserLanguage(id, languageId);
      return ApiResponse.success(res, result.message, result.language);
    } catch (error) {
      next(error);
    }
  }

  async getUserVideos(req, res, next) {
    try {
      const data = await videoService.getUserVideos(req.user.id, req.query);
      return ApiResponse.success(res, 'User videos fetched successfully', data);
    } catch (error) {
      next(error);
    }
  }

  async acceptDisclaimer(req, res, next) {
    try {
      const result = await videoService.acceptDisclaimer(req.user.id);
      return ApiResponse.success(res, result.message);
    } catch (error) {
      next(error);
    }
  }

  async recordProgress(req, res, next) {
    try {
      const { id } = req.params;
      const { watchedSecs } = req.body;
      const progress = await videoService.recordProgress(
        req.user.id,
        id,
        watchedSecs || 0
      );
      return ApiResponse.success(res, 'Progress saved', progress);
    } catch (error) {
      next(error);
    }
  }

  async recordPlaybackHeartbeat(req, res, next) {
    try {
      const { id } = req.params;
      const { sessionWatchedSecs } = req.body;
      const progress = await videoService.recordPlaybackHeartbeat(
        req.user.id,
        id,
        sessionWatchedSecs || 0
      );
      return ApiResponse.success(res, 'Heartbeat logged', progress);
    } catch (error) {
      next(error);
    }
  }

  async getSecureVideoPlayback(req, res, next) {
    try {
      const { id } = req.params;
      const accessData = await videoService.getSecureVideoPlayback(req.user.id, id);
      return ApiResponse.success(res, 'Video access granted', accessData);
    } catch (error) {
      next(error);
    }
  }

  async getProgressStatus(req, res, next) {
    try {
      const status = await videoService.getProgressStatus(req.user.id);
      return ApiResponse.success(res, 'Video progress status fetched', status);
    } catch (error) {
      next(error);
    }
  }

  async getLockedVideos(req, res, next) {
    try {
      const lockedVideos = await videoService.getLockedVideos(req.user.id);
      return ApiResponse.success(res, 'Locked videos fetched', lockedVideos);
    } catch (error) {
      next(error);
    }
  }

  async resetUserVideoProgress(req, res, next) {
    try {
      const { id } = req.params;
      const result = await videoService.resetUserVideoProgress(id);
      return ApiResponse.success(res, result.message);
    } catch (error) {
      next(error);
    }
  }

  async getUserSnapshotAdmin(req, res, next) {
    try {
      const { id } = req.params;
      const snapshot = await videoService.getUserSnapshotAdmin(id);
      return ApiResponse.success(res, 'User snapshot details fetched', snapshot);
    } catch (error) {
      next(error);
    }
  }

  async setUserLanguage(req, res, next) {
    try {
      const { languageId } = req.body;
      if (!languageId) {
        return ApiResponse.error(res, 'languageId is required', 400);
      }
      const data = await videoService.setUserLanguage(req.user.id, languageId);
      return ApiResponse.success(res, 'Learning language selected successfully', data);
    } catch (error) {
      next(error);
    }
  }
}

module.exports = new VideoController();
