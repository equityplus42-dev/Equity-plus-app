const express = require('express');
const router = express.Router();
const developerController = require('../../controllers/developer.controller');
const authMiddleware = require('../../middleware/auth.middleware');
const developerMiddleware = require('../../middleware/developer.middleware');

// All developer management endpoints are strictly guarded by authMiddleware + developerMiddleware
router.use(authMiddleware, developerMiddleware);

// Get current Test User status
router.get('/test-user/status', developerController.getTestUserStatus);

// Grant payment bypass to Test User
router.post('/test-user/bypass-payment', developerController.bypassPaymentForTestUser);

// Re-create / reseed Test User
router.post('/test-user/reseed', developerController.reseedTestUser);

// KILL TEST USER permanently from database
router.delete('/test-user/kill', developerController.killTestUser);

// User Joining Snapshots (Developer Only)
router.get('/joining-snapshots', developerController.getJoiningSnapshots);

module.exports = router;
