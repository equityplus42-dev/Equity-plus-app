const express = require('express');
const router = express.Router();
const languageRequestController = require('../../controllers/languageRequest.controller');
const authMiddleware = require('../../middleware/auth.middleware');
const roleMiddleware = require('../../middleware/role.middleware');

// User routes
router.post('/my', authMiddleware, languageRequestController.createRequest);
router.get('/my', authMiddleware, languageRequestController.getUserRequests);

// Admin routes
router.get('/admin', authMiddleware, roleMiddleware(['ADMIN']), languageRequestController.getAdminRequests);
router.patch('/admin/:id/review', authMiddleware, roleMiddleware(['ADMIN']), languageRequestController.reviewRequest);

module.exports = router;
