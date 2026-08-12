const { v2: cloudinaryV2 } = require('cloudinary');
const env = require('./env');
const logger = require('../utils/logger');

// ── Primary Cloudinary Config (Avatars, Thumbnails, Marketing images) ──────────
const primaryConfig = {
  cloud_name: env.CLOUDINARY_CLOUD_NAME,
  api_key: env.CLOUDINARY_API_KEY,
  api_secret: env.CLOUDINARY_API_SECRET,
};

if (primaryConfig.cloud_name && primaryConfig.api_key && primaryConfig.api_secret) {
  logger.info(`Primary Cloudinary ready: cloud="${primaryConfig.cloud_name}"`);
} else {
  logger.warn('Primary Cloudinary env vars missing. Image uploads will use fallback mock URLs.');
}

// ── Dedicated Video Cloudinary Config (Separate Account for Video Streaming) ───
const videoConfig = {
  cloud_name: env.CLOUDINARY_VIDEO_CLOUD_NAME,
  api_key: env.CLOUDINARY_VIDEO_API_KEY,
  api_secret: env.CLOUDINARY_VIDEO_API_SECRET,
};

if (videoConfig.cloud_name && videoConfig.api_key && videoConfig.api_secret) {
  logger.info(`Dedicated Video Cloudinary ready: cloud="${videoConfig.cloud_name}" (STRICT EXCLUSIVE VIDEO ACCOUNT)`);
} else {
  logger.error('CRITICAL: Dedicated Video Cloudinary (CLOUDINARY_VIDEO_*) env vars missing! Video uploads will fail.');
}

// ── Helper: Upload using a specific config (bypasses singleton limitation) ──────
function uploadWithConfig(config, buffer, options) {
  const { Readable } = require('stream');
  const fs = require('fs');
  const path = require('path');
  const os = require('os');

  return new Promise((resolve, reject) => {
    // Clone a temporary config and use it for this specific upload
    cloudinaryV2.config(config);

    if (options.resource_type === 'video') {
      // For video files, use Cloudinary's upload_large API with 20MB chunking.
      // This prevents Cloudinary's API from rejecting large single-payload HTTP requests with status 413.
      const tempDir = fs.existsSync(path.join(__dirname, '../uploads/temp'))
        ? path.join(__dirname, '../uploads/temp')
        : os.tmpdir();

      const tempFilePath = path.join(tempDir, `video_upload_${Date.now()}_${Math.random().toString(36).substring(7)}.tmp`);

      fs.writeFile(tempFilePath, buffer, (err) => {
        if (err) return reject(err);

        const uploadOptions = {
          chunk_size: 20 * 1024 * 1024, // 20MB chunks
          ...options,
        };

        cloudinaryV2.uploader.upload_large(tempFilePath, uploadOptions, (error, result) => {
          // Always clean up the temp file
          fs.unlink(tempFilePath, () => {});

          if (error) return reject(error);
          resolve(result);
        });
      });
    } else {
      // For images, standard single-stream upload is fast and lightweight
      const stream = cloudinaryV2.uploader.upload_stream(options, (error, result) => {
        if (error) return reject(error);
        resolve(result);
      });
      const readable = new Readable();
      readable.push(buffer);
      readable.push(null);
      readable.pipe(stream);
    }
  });
}

module.exports = {
  primaryConfig,
  videoConfig,
  uploadWithConfig,
  cloudinaryV2,
};


