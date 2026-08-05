const express = require('express');
const router = express.Router();
const videoController = require('../../controllers/video.controller');
const authMiddleware = require('../../middleware/auth.middleware');
const roleMiddleware = require('../../middleware/role.middleware');

// User routes
router.get('/', authMiddleware, videoController.getUserVideos);
router.get('/progress', authMiddleware, videoController.getProgressStatus);
router.get('/locked', authMiddleware, videoController.getLockedVideos);
router.get('/:id/access', authMiddleware, videoController.getSecureVideoPlayback);
router.post('/disclaimer/accept', authMiddleware, videoController.acceptDisclaimer);
router.post('/:id/progress', authMiddleware, videoController.recordProgress);
router.post('/:id/heartbeat', authMiddleware, videoController.recordPlaybackHeartbeat);

// Admin routes
router.get('/admin', authMiddleware, roleMiddleware(['ADMIN']), videoController.getAllVideosAdmin);
router.post('/admin', authMiddleware, roleMiddleware(['ADMIN']), videoController.createVideo);
router.patch('/admin/reorder', authMiddleware, roleMiddleware(['ADMIN']), videoController.reorderVideos);
router.delete('/admin/:id', authMiddleware, roleMiddleware(['ADMIN']), videoController.deleteVideo);
router.put('/admin/users/:id/language', authMiddleware, roleMiddleware(['ADMIN']), videoController.assignUserLanguage);
router.post('/admin/users/:id/reset-video-progress', authMiddleware, roleMiddleware(['ADMIN']), videoController.resetUserVideoProgress);
router.get('/admin/users/:id/snapshot', authMiddleware, roleMiddleware(['ADMIN']), videoController.getUserSnapshotAdmin);

module.exports = router;
