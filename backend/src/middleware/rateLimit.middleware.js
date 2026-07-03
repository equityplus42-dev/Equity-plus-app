const rateLimit = require('express-rate-limit');
const ApiResponse = require('../utils/apiResponse');

// 1. Login rate limiter (5 requests per minute)
const loginLimiter = rateLimit({
  windowMs: 60 * 1000, // 1 minute
  max: 5,
  standardHeaders: true,
  legacyHeaders: false,
  handler: (req, res) => {
    return ApiResponse.error(
      res, 
      'Too many login attempts, please try again in a minute.', 
      429, 
      'AUTH_RATE_LIMIT_LOGIN'
    );
  }
});

// 2. Register rate limiter (3 requests per minute)
const registerLimiter = rateLimit({
  windowMs: 60 * 1000, // 1 minute
  max: 3,
  standardHeaders: true,
  legacyHeaders: false,
  handler: (req, res) => {
    return ApiResponse.error(
      res, 
      'Too many registration attempts, please try again in a minute.', 
      429, 
      'AUTH_RATE_LIMIT_REGISTER'
    );
  }
});

// 3. Forgot password rate limiter (3 requests per minute)
const forgotPasswordLimiter = rateLimit({
  windowMs: 60 * 1000, // 1 minute
  max: 3,
  standardHeaders: true,
  legacyHeaders: false,
  handler: (req, res) => {
    return ApiResponse.error(
      res, 
      'Too many requests, please try again in a minute.', 
      429, 
      'AUTH_RATE_LIMIT_FORGOT'
    );
  }
});

module.exports = {
  loginLimiter,
  registerLimiter,
  forgotPasswordLimiter
};
