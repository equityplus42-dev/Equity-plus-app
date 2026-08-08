const express = require('express');
const router = express.Router();
const paymentController = require('../../controllers/payment.controller');
const authMiddleware = require('../../middleware/auth.middleware');
const roleMiddleware = require('../../middleware/role.middleware');

// User payment endpoints
router.post('/create-order', authMiddleware, paymentController.createOrder);
router.post('/verify', authMiddleware, paymentController.verifyPayment);
router.get('/my', authMiddleware, paymentController.getUserPayments);

// Admin payment endpoints
router.get('/admin', authMiddleware, roleMiddleware(['ADMIN']), paymentController.getAdminPayments);

module.exports = router;
