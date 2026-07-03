const express = require('express');
const router = express.Router();
const adminController = require('../../controllers/admin.controller');
const authMiddleware = require('../../middleware/auth.middleware');
const adminMiddleware = require('../../middleware/admin.middleware');

router.get('/stats', authMiddleware, adminMiddleware, adminController.getStats);
router.patch('/users/:userId/approval', authMiddleware, adminMiddleware, adminController.updateUserApproval);
router.patch('/users/:userId/regenerate-referral', authMiddleware, adminMiddleware, adminController.regenerateReferral);
router.get('/referrals/pending', authMiddleware, adminMiddleware, adminController.getPendingReferrals);
router.patch('/referrals/:referralId/approve', authMiddleware, adminMiddleware, adminController.approveReferral);
router.patch('/referrals/:referralId/reject', authMiddleware, adminMiddleware, adminController.rejectReferral);
router.put('/settings', authMiddleware, adminMiddleware, adminController.updateSetting);

module.exports = router;
