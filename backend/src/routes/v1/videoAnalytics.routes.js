const express = require('express');
const router = express.Router();
const videoAnalyticsController = require('../../controllers/videoAnalytics.controller');
const authMiddleware = require('../../middleware/auth.middleware');
const roleMiddleware = require('../../middleware/role.middleware');

router.get('/admin/global', authMiddleware, roleMiddleware(['ADMIN']), videoAnalyticsController.getGlobalAnalytics);
router.get('/admin/:videoId', authMiddleware, roleMiddleware(['ADMIN']), videoAnalyticsController.getVideoAnalytics);

module.exports = router;
