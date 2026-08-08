const uploadPipelineService = require('../services/uploadPipeline.service');
const cloudinaryService = require('../services/cloudinary.service');
const ApiResponse = require('../utils/apiResponse');

class UploadPipelineController {
  async processUploadPipeline(req, res, next) {
    try {
      const { title, description, videoUrl, thumbnailUrl, duration, languageId, productId, status } = req.body;
      const result = await uploadPipelineService.processUploadPipeline({
        title,
        description,
        videoUrl,
        thumbnailUrl,
        duration,
        languageId,
        productId,
        status,
      });
      return ApiResponse.success(res, result.message, result, 201);
    } catch (error) {
      next(error);
    }
  }

  async uploadMedia(req, res, next) {
    try {
      if (!req.file) {
        return ApiResponse.error(res, 'No file uploaded', 400);
      }

      const isVideo = req.file.mimetype.startsWith('video/');
      let fileUrl;
      let videoDuration = 0;

      if (isVideo) {
        const result = await cloudinaryService.uploadVideo(req.file.buffer, 'videos');
        fileUrl = result.url;
        videoDuration = result.duration || 0;
      } else {
        fileUrl = await cloudinaryService.uploadImage(req.file.buffer, 'thumbnails');
      }

      return ApiResponse.success(res, 'File uploaded successfully', {
        url: fileUrl,
        isVideo,
        duration: videoDuration, // actual seconds from Cloudinary metadata
      });
    } catch (error) {
      next(error);
    }
  }
}

module.exports = new UploadPipelineController();
