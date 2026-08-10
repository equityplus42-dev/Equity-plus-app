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
  return new Promise((resolve, reject) => {
    // Clone a temporary config and use it for this specific upload
    cloudinaryV2.config(config);
    const stream = cloudinaryV2.uploader.upload_stream(options, (error, result) => {
      if (error) return reject(error);
      resolve(result);
    });
    const readable = new Readable();
    readable.push(buffer);
    readable.push(null);
    readable.pipe(stream);
  });
}

module.exports = {
  primaryConfig,
  videoConfig,
  uploadWithConfig,
  cloudinaryV2,
};


