const express = require('express');
const router = express.Router();
const notificationController = require('../../controllers/notification.controller');
const authMiddleware = require('../../middleware/auth.middleware');

router.get('/', authMiddleware, notificationController.getNotifications);
router.patch('/read-all', authMiddleware, notificationController.markAllRead);
router.patch('/:id/read', authMiddleware, notificationController.markAsRead);

module.exports = router;
