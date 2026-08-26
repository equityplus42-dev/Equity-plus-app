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

  /**
   * Generate a Cloudinary signed upload signature so the Flutter client can upload
   * DIRECTLY to Cloudinary's API — completely bypassing Vercel's 4.5MB serverless payload limit.
   * POST /upload-pipeline/cloudinary-signature
   */
  async getCloudinaryUploadSignature(req, res, next) {
    try {
      const hasVideoConfig = videoConfig.cloud_name && videoConfig.api_key && videoConfig.api_secret;
      if (!hasVideoConfig) {
        return ApiResponse.error(res, 'Cloudinary video account not configured on server.', 500);
      }

      const folder = (req.body && req.body.folder) || 'videos';
      const timestamp = Math.round(Date.now() / 1000);

      // Params to sign — must match exactly what the client will send in the multipart form
      const paramsToSign = {
        eager: 'sp_hd/m3u8|sp_sd/m3u8|c_limit,h_1080,q_auto,w_1920/mp4|c_limit,h_720,q_auto,w_1280/mp4|c_limit,h_480,q_auto,w_854/mp4|c_limit,h_360,q_auto,w_640/mp4|c_limit,h_240,q_auto,w_426/mp4',
        eager_async: 'true',
        folder,
        timestamp,
      };

      // Set the dedicated video account config before signing
      cloudinaryV2.config(videoConfig);
      const signature = cloudinaryV2.utils.api_sign_request(paramsToSign, videoConfig.api_secret);

      return ApiResponse.success(res, 'Cloudinary upload signature generated', {
        signature,
        timestamp,
        apiKey: videoConfig.api_key,
        cloudName: videoConfig.cloud_name,
        folder,
        eager: paramsToSign.eager,
        eagerAsync: true,
        // Flutter POSTs the file directly to this URL using the signature — no server proxy needed
        uploadUrl: `https://api.cloudinary.com/v1_1/${videoConfig.cloud_name}/video/upload`,
      });
    } catch (error) {
      next(error);
    }
  }
}

module.exports = new UploadPipelineController();
