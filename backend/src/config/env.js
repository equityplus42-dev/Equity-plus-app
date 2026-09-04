const dotenv = require('dotenv');
dotenv.config();

const requiredEnv = ['DATABASE_URL'];

// Log warnings for missing critical variables
requiredEnv.forEach((key) => {
  if (!process.env[key]) {
    console.error(`FATAL ERROR: Environment variable ${key} is required but missing.`);
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
  CLOUDINARY_VIDEO_CLOUD_NAME: process.env.CLOUDINARY_VIDEO_CLOUD_NAME,
  CLOUDINARY_VIDEO_API_KEY: process.env.CLOUDINARY_VIDEO_API_KEY,
  CLOUDINARY_VIDEO_API_SECRET: process.env.CLOUDINARY_VIDEO_API_SECRET,
  CLOUDFLARE_R2_ACCOUNT_ID: process.env.CLOUDFLARE_R2_ACCOUNT_ID,
  CLOUDFLARE_R2_ACCESS_KEY_ID: process.env.CLOUDFLARE_R2_ACCESS_KEY_ID,
  CLOUDFLARE_R2_SECRET_ACCESS_KEY: process.env.CLOUDFLARE_R2_SECRET_ACCESS_KEY,
  CLOUDFLARE_R2_BUCKET_NAME: process.env.CLOUDFLARE_R2_BUCKET_NAME,
  CLOUDFLARE_R2_PUBLIC_DOMAIN: process.env.CLOUDFLARE_R2_PUBLIC_DOMAIN,
  CLOUDFLARE_STREAM_ACCOUNT_ID: process.env.CLOUDFLARE_STREAM_ACCOUNT_ID,
  CLOUDFLARE_STREAM_API_TOKEN: process.env.CLOUDFLARE_STREAM_API_TOKEN,
  RAZORPAY_KEY_ID: process.env.RAZORPAY_KEY_ID,
  RAZORPAY_KEY_SECRET: process.env.RAZORPAY_KEY_SECRET,
  LOG_LEVEL: process.env.LOG_LEVEL,
  APP_DOMAIN: process.env.APP_DOMAIN || 'vridhi-network-app.vercel.app',
};
