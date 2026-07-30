const express = require('express');
const router = express.Router();
const authController = require('../../controllers/auth.controller');
const { registerSchema, loginSchema, requestOtpSchema, verifyOtpSchema, resetPasswordSchema, changePasswordSchema } = require('../../validators/auth.validator');
const validationMiddleware = require('../../middleware/validation.middleware');
const authMiddleware = require('../../middleware/auth.middleware');
const { loginLimiter, registerLimiter, forgotPasswordLimiter } = require('../../middleware/rateLimit.middleware');

router.post('/register', registerLimiter, validationMiddleware(registerSchema), authController.register);
router.post('/login', loginLimiter, validationMiddleware(loginSchema), authController.login);

router.post('/forgot-password/request-otp', forgotPasswordLimiter, validationMiddleware(requestOtpSchema), authController.requestPasswordResetOtp);
router.post('/forgot-password/verify-otp', forgotPasswordLimiter, validationMiddleware(verifyOtpSchema), authController.verifyPasswordResetOtp);
router.post('/forgot-password/reset', forgotPasswordLimiter, validationMiddleware(resetPasswordSchema), authController.resetPassword);

router.post('/change-password', authMiddleware, validationMiddleware(changePasswordSchema), authController.changePassword);

module.exports = router;
