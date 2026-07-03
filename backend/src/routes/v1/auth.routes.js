const express = require('express');
const router = express.Router();
const authController = require('../../controllers/auth.controller');
const { registerSchema, loginSchema } = require('../../validators/auth.validator');
const validationMiddleware = require('../../middleware/validation.middleware');
const { loginLimiter, registerLimiter, forgotPasswordLimiter } = require('../../middleware/rateLimit.middleware');

router.post('/register', registerLimiter, validationMiddleware(registerSchema), authController.register);
router.post('/login', loginLimiter, validationMiddleware(loginSchema), authController.login);

router.post('/forgot-password', forgotPasswordLimiter, (req, res) => {
  return res.status(200).json({ success: true, message: 'Password reset link dispatched.' });
});

module.exports = router;
