const express = require('express');
const router = express.Router();
const announcementController = require('../../controllers/announcement.controller');
const authMiddleware = require('../../middleware/auth.middleware');
const roleMiddleware = require('../../middleware/role.middleware');

router.get('/my', authMiddleware, announcementController.getUserAnnouncements);
router.get('/admin', authMiddleware, roleMiddleware(['ADMIN']), announcementController.getAdminAnnouncements);
router.post('/admin', authMiddleware, roleMiddleware(['ADMIN']), announcementController.createAnnouncement);

module.exports = router;
