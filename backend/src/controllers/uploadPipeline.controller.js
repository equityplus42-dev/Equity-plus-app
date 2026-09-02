const uploadPipelineService = require('../services/uploadPipeline.service');
const cloudinaryService = require('../services/cloudinary.service');
const cloudflareR2Service = require('../services/cloudflareR2.service');
const cloudflareStreamService = require('../services/cloudflareStream.service');
const { videoConfig, cloudinaryV2 } = require('../config/cloudinary');
const ApiResponse = require('../utils/apiResponse');

class UploadPipelineController {
  async processUploadPipeline(req, res, next) {
    try {
      const { title, description, videoUrl, thumbnailUrl, duration, languageId, productId, status, storageProvider } = req.body;
      const result = await uploadPipelineService.processUploadPipeline({
        title,
        description,
        videoUrl,
        thumbnailUrl,
        duration,
        languageId,
        productId,
        status,
        storageProvider,
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

      const path = require('path');
      const VIDEO_EXTENSIONS = new Set(['.mp4', '.mov', '.avi', '.mkv', '.webm', '.flv', '.wmv', '.m4v', '.3gp', '.mpeg', '.mpg']);
      const ext = path.extname(req.file.originalname).toLowerCase();
      const isVideo = req.file.mimetype.startsWith('video/') || VIDEO_EXTENSIONS.has(ext);
      const provider = 'CLOUDFLARE_R2';
      const fileSize = req.file.size || (req.file.buffer ? req.file.buffer.length : 0);
      let usedProvider = 'CLOUDFLARE_R2';
      let fileUrl;
      let r2ObjectKey = null; // Permanent R2 object key (null for non-R2 providers)
      let videoDuration = 0;

      if (isVideo) {
        // All video uploads route strictly to Cloudflare R2 Storage (Direct High Speed)
        const r2Result = await cloudflareR2Service.uploadFile(req.file.buffer, 'videos', req.file.originalname, req.file.mimetype);
        fileUrl = r2Result.url;
        r2ObjectKey = r2Result.r2ObjectKey;
        const reqDur = parseInt(req.body.duration || req.query.duration, 10);
        videoDuration = !isNaN(reqDur) && reqDur > 0 ? reqDur : 0;
      } else {
        // Image files
        if (usedProvider === 'CLOUDFLARE_R2') {
          const r2Result = await cloudflareR2Service.uploadFile(req.file.buffer, 'thumbnails', req.file.originalname, req.file.mimetype);
          fileUrl = r2Result.url;
          r2ObjectKey = r2Result.r2ObjectKey;
        } else {
          fileUrl = await cloudinaryService.uploadImage(req.file.buffer, 'thumbnails');
        }
      }

      return ApiResponse.success(res, 'File uploaded successfully', {
        url: fileUrl,
        r2ObjectKey,   // Permanent R2 object key — store this in Video.r2ObjectKey
        isVideo,
        duration: videoDuration,
        provider: usedProvider,
        fileSize,
      });
    } catch (error) {
      next(error);
    }
  }

  async getPresignedUploadUrl(req, res, next) {
    try {
      const { folder = 'videos', filename = 'file.mp4', mimeType = 'video/mp4' } = req.body;
      const result = await cloudflareR2Service.generateUploadUrl(folder, filename, mimeType);
      return ApiResponse.success(res, 'Presigned upload URL generated successfully', result);
    } catch (error) {
      next(error);
    }
  }

  /**
   * Generate a Cloudinary signed upload signature so the Flutter client can upload
   * DIRECTLY to Cloudinary's API — completely bypassing Vercel's 4.5MB serverless payload limit.
   * POST /upload-pipeline/cloudinary-signature
   */
  async getCloudinaryUploadSignature(req, res, next) {
    try {
      return ApiResponse.error(res, 'Cloudinary video uploads are discontinued. All video uploads must use Cloudflare R2 (/upload-pipeline/presigned-url).', 400);
    } catch (error) {
      next(error);
    }
  }
}

module.exports = new UploadPipelineController();
