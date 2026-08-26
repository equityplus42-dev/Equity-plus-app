const express = require('express');
const router = express.Router();
const notificationController = require('../../controllers/notification.controller');
const authMiddleware = require('../../middleware/auth.middleware');
const roleMiddleware = require('../../middleware/role.middleware');

router.get('/', authMiddleware, notificationController.getNotifications);
router.patch('/read-all', authMiddleware, notificationController.markAllRead);
router.patch('/:id/read', authMiddleware, notificationController.markAsRead);

// Clear all notifications for the authenticated user (works for both user & admin)
router.delete('/clear-all', authMiddleware, notificationController.clearMyNotifications);

// Admin-only: wipe all notifications for every user in the system
router.delete('/admin/clear-all', authMiddleware, roleMiddleware(['ADMIN']), notificationController.clearAllNotifications);

module.exports = router;
