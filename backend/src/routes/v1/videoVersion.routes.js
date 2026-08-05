const express = require('express');
const router = express.Router();
const videoVersionController = require('../../controllers/videoVersion.controller');
const authMiddleware = require('../../middleware/auth.middleware');
const roleMiddleware = require('../../middleware/role.middleware');

router.get('/admin/:videoId', authMiddleware, roleMiddleware(['ADMIN']), videoVersionController.getVersionHistory);
router.post('/admin/:videoId', authMiddleware, roleMiddleware(['ADMIN']), videoVersionController.createVersion);
router.post('/admin/:videoId/restore/:versionId', authMiddleware, roleMiddleware(['ADMIN']), videoVersionController.restoreVersion);

module.exports = router;
