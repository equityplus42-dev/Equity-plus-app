const cloudinary = require('cloudinary').v2;
const env = require('./env');
const logger = require('../utils/logger');

// Primary Cloudinary instance (Avatars, Thumbnails, Campaigns, Marketing images)
const cloudName = env.CLOUDINARY_CLOUD_NAME;
const apiKey = env.CLOUDINARY_API_KEY;
const apiSecret = env.CLOUDINARY_API_SECRET;

if (cloudName && apiKey && apiSecret) {
  cloudinary.config({
    cloud_name: cloudName,
    api_key: apiKey,
    api_secret: apiSecret,
  });
  logger.info('Primary Cloudinary configured successfully.');
} else {
  logger.warn('Primary Cloudinary environment variables missing. Image uploads will use fallback mocks.');
}

// Dedicated Video Cloudinary instance (Separate Account for Video Streaming Assets)
const videoCloudinary = require('cloudinary').v2;
const videoCloudName = env.CLOUDINARY_VIDEO_CLOUD_NAME;
const videoApiKey = env.CLOUDINARY_VIDEO_API_KEY;
const videoApiSecret = env.CLOUDINARY_VIDEO_API_SECRET;

if (videoCloudName && videoApiKey && videoApiSecret) {
  videoCloudinary.config({
    cloud_name: videoCloudName,
    api_key: videoApiKey,
    api_secret: videoApiSecret,
  });
  logger.info('Video Cloudinary account configured successfully.');
} else {
  logger.warn('Video Cloudinary environment variables missing. Video uploads will fallback to primary Cloudinary or mocks.');
}

module.exports = {
  cloudinary,
  videoCloudinary,
};
