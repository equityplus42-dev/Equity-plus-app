const express = require('express');
const router = express.Router();
const refundController = require('../../controllers/refund.controller');
const authMiddleware = require('../../middleware/auth.middleware');
const roleMiddleware = require('../../middleware/role.middleware');

// User refund endpoints
router.post('/request', authMiddleware, refundController.createRefundRequest);
router.get('/my', authMiddleware, refundController.getUserRefundRequests);

// Admin refund endpoints
router.get('/admin', authMiddleware, roleMiddleware(['ADMIN']), refundController.getAdminRefundRequests);
router.patch('/admin/:id/review', authMiddleware, roleMiddleware(['ADMIN']), refundController.reviewRefundRequest);

module.exports = router;
