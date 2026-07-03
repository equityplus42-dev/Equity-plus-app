const cloudinary = require('cloudinary').v2;
const env = require('./env');
const logger = require('../utils/logger');

const cloudName = env.CLOUDINARY_CLOUD_NAME;
const apiKey = env.CLOUDINARY_API_KEY;
const apiSecret = env.CLOUDINARY_API_SECRET;

if (cloudName && apiKey && apiSecret) {
  cloudinary.config({
    cloud_name: cloudName,
    api_key: apiKey,
    api_secret: apiSecret,
  });
  logger.info('Cloudinary configured successfully.');
} else {
  logger.warn('Cloudinary environment variables are missing. File uploads will fallback to local mocks.');
}

module.exports = cloudinary;
