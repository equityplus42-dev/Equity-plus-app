const express = require('express');
const router = express.Router();
const passkeyController = require('../../controllers/passkey.controller');
const authMiddleware = require('../../middleware/auth.middleware');
const { loginLimiter } = require('../../middleware/rateLimit.middleware');

// Public endpoints (Login via discoverable or specified Passkey)
router.post('/login/options', loginLimiter, (req, res, next) => passkeyController.generateAuthenticationOptions(req, res, next));
router.post('/login/verify', loginLimiter, (req, res, next) => passkeyController.verifyAuthentication(req, res, next));
router.post('/reset-password/options', loginLimiter, (req, res, next) => passkeyController.generatePasswordResetOptions(req, res, next));
router.post('/reset-password/verify', loginLimiter, (req, res, next) => passkeyController.verifyPasswordReset(req, res, next));

// Authenticated endpoints (Registering new Passkey and managing credentials)
router.post('/register/options', authMiddleware, (req, res, next) => passkeyController.generateRegistrationOptions(req, res, next));
router.post('/register/verify', authMiddleware, (req, res, next) => passkeyController.verifyRegistration(req, res, next));
router.get('/credentials', authMiddleware, (req, res, next) => passkeyController.listPasskeys(req, res, next));
router.delete('/credentials/:id', authMiddleware, (req, res, next) => passkeyController.deletePasskey(req, res, next));
router.patch('/credentials/:id', authMiddleware, (req, res, next) => passkeyController.renamePasskey(req, res, next));

module.exports = router;
