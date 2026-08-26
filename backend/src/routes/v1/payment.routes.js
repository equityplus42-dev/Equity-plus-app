const express = require('express');
const router = express.Router();
const paymentController = require('../../controllers/payment.controller');
const authMiddleware = require('../../middleware/auth.middleware');
const roleMiddleware = require('../../middleware/role.middleware');

// Static user & common endpoints
router.get('/membership-price', authMiddleware, paymentController.getMembershipPrice);
router.post('/create-order', authMiddleware, paymentController.createOrder);
router.post('/verify', authMiddleware, paymentController.verifyPayment);
router.get('/my', authMiddleware, paymentController.getUserPayments);
router.post('/request-cash', authMiddleware, paymentController.requestCashPayment);
router.post('/bypass-payment', authMiddleware, paymentController.bypassPayment);

// Admin & Developer payment endpoints
router.get('/admin', authMiddleware, roleMiddleware(['ADMIN', 'DEVELOPER']), paymentController.getAdminPayments);
router.post('/admin/membership-price', authMiddleware, roleMiddleware(['ADMIN', 'DEVELOPER']), paymentController.updateMembershipPrice);
router.post('/admin/reset-user-payment', authMiddleware, roleMiddleware(['ADMIN', 'DEVELOPER']), paymentController.resetUserPaymentStatus);

// Dynamic parameterized endpoints (MUST BE AT THE END)
router.get('/status/:paymentId', authMiddleware, paymentController.getPaymentStatus);
router.post('/approve-cash/:paymentId', authMiddleware, roleMiddleware(['ADMIN', 'DEVELOPER']), paymentController.approveCashPayment);

module.exports = router;
