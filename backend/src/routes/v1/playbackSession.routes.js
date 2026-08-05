const express = require('express');
const router = express.Router();
const playbackSessionController = require('../../controllers/playbackSession.controller');
const authMiddleware = require('../../middleware/auth.middleware');

router.post('/:videoId/start', authMiddleware, playbackSessionController.startSession);
router.post('/ping/:sessionId', authMiddleware, playbackSessionController.pingSession);
router.post('/end/:sessionId', authMiddleware, playbackSessionController.endSession);
router.get('/:videoId/resume', authMiddleware, playbackSessionController.getLatestPosition);

module.exports = router;
