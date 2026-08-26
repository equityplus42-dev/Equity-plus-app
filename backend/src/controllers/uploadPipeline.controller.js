const uploadPipelineService = require('../services/uploadPipeline.service');
const cloudinaryService = require('../services/cloudinary.service');
const cloudflareR2Service = require('../services/cloudflareR2.service');
const cloudflareStreamService = require('../services/cloudflareStream.service');
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
      const VIDEO_EXTENSIONS = new Set([
        '.mp4', '.m4v', '.mp4v', '.mkv', '.mov', '.qt', '.avi', '.webm',
        '.flv', '.f4v', '.wmv', '.asf', '.3gp', '.3g2', '.mpeg', '.mpg',
        '.m2v', '.ts', '.mts', '.m2ts', '.ogv', '.ogg', '.vob', '.divx', '.xvid', '.rm', '.rmvb'
      ]);
      const ext = path.extname(req.file.originalname).toLowerCase();
      const mime = (req.file.mimetype || '').toLowerCase();
      const isVideo = mime.startsWith('video/') || mime.includes('matroska') || mime.includes('quicktime') || VIDEO_EXTENSIONS.has(ext);
      const provider = ((req.body && req.body.storageProvider) || (req.query && req.query.storageProvider) || 'CLOUDINARY').toUpperCase();
      const CLOUDINARY_MAX_VIDEO_SIZE = 100 * 1024 * 1024; // 100MB limit for Cloudinary video uploads
      const fileSize = req.file.size || (req.file.buffer ? req.file.buffer.length : 0);
      let usedProvider = provider;
      let fileUrl;
      let r2ObjectKey = null; // Permanent R2 object key (null for non-R2 providers)
      let videoDuration = 0;

      if (isVideo) {
        // If video size exceeds 100MB and provider is CLOUDINARY, auto-route to Cloudflare R2 Storage
        if (provider === 'CLOUDINARY' && fileSize > CLOUDINARY_MAX_VIDEO_SIZE) {
          console.info(`[UploadPipeline] Video size is ${(fileSize / (1024 * 1024)).toFixed(1)}MB (> 100MB Cloudinary limit). Automatically routing to Cloudflare R2 Storage.`);
          usedProvider = 'CLOUDFLARE_R2';
        }

        if (usedProvider === 'CLOUDFLARE_R2') {
          // uploadFile now returns { r2ObjectKey, url } — the URL is a 1-hour preview URL.
          // The permanent storage identity is r2ObjectKey (e.g. "videos/<uuid>.mp4").
          const r2Result = await cloudflareR2Service.uploadFile(req.file.buffer, 'videos', req.file.originalname, req.file.mimetype);
          fileUrl = r2Result.url;
          r2ObjectKey = r2Result.r2ObjectKey;
          const reqDur = parseInt(req.body.duration || req.query.duration, 10);
          videoDuration = !isNaN(reqDur) && reqDur > 0 ? reqDur : 0;
        } else if (usedProvider === 'CLOUDFLARE_STREAM') {
          const result = await cloudflareStreamService.uploadVideo(req.file.buffer, req.file.originalname);
          fileUrl = result.videoUrl;
          videoDuration = result.duration || 0;
        } else {
          // Dedicated Video Cloudinary account (CLOUDINARY_VIDEO_*)
          const result = await cloudinaryService.uploadVideo(req.file.buffer, 'videos');
          fileUrl = result.url;
          const reqDur = parseInt(req.body.duration || req.query.duration, 10);
          videoDuration = (result.duration && result.duration > 0) ? result.duration : (!isNaN(reqDur) && reqDur > 0 ? reqDur : 0);
        }
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
}

module.exports = new UploadPipelineController();
