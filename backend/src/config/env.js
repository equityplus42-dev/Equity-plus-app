const dotenv = require('dotenv');
dotenv.config();

const requiredEnv = ['DATABASE_URL'];

// Log warnings for missing critical variables
requiredEnv.forEach((key) => {
  if (!process.env[key]) {
    console.error(`FATAL ERROR: Environment variable ${key} is required but missing.`);
    process.exit(1);
  }
});

module.exports = {
  PORT: parseInt(process.env.PORT || '5000', 10),
  NODE_ENV: process.env.NODE_ENV || 'development',
  DATABASE_URL: process.env.DATABASE_URL,
  JWT_SECRET: process.env.JWT_SECRET || 'referral_system_secret_key_123',
  JWT_EXPIRES_IN: process.env.JWT_EXPIRES_IN || '7d',
  CLOUDINARY_CLOUD_NAME: process.env.CLOUDINARY_CLOUD_NAME,
  CLOUDINARY_API_KEY: process.env.CLOUDINARY_API_KEY,
  CLOUDINARY_API_SECRET: process.env.CLOUDINARY_API_SECRET,
  LOG_LEVEL: process.env.LOG_LEVEL,
  APP_DOMAIN: process.env.APP_DOMAIN || 'referral-system.com',
};
