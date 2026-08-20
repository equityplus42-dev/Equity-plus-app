const express = require('express');
const router = express.Router();
const paymentController = require('../../controllers/payment.controller');
const authMiddleware = require('../../middleware/auth.middleware');
const roleMiddleware = require('../../middleware/role.middleware');

// User payment endpoints
router.post('/create-order', authMiddleware, paymentController.createOrder);
router.post('/verify', authMiddleware, paymentController.verifyPayment);
router.get('/my', authMiddleware, paymentController.getUserPayments);
router.post('/request-cash', authMiddleware, paymentController.requestCashPayment);
router.get('/status/:paymentId', authMiddleware, paymentController.getPaymentStatus);

// Admin payment endpoints
router.get('/admin', authMiddleware, roleMiddleware(['ADMIN']), paymentController.getAdminPayments);
router.post('/approve-cash/:paymentId', authMiddleware, roleMiddleware(['ADMIN']), paymentController.approveCashPayment);

module.exports = router;
