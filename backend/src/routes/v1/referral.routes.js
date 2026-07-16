const express = require('express');
const router = express.Router();
const referralController = require('../../controllers/referral.controller');
const authMiddleware = require('../../middleware/auth.middleware');

router.get('/', authMiddleware, referralController.getReferrals);
router.get('/stats', authMiddleware, referralController.getStats);
router.get('/qr', authMiddleware, referralController.getReferralQR);
router.get('/my-code', authMiddleware, referralController.getReferralQR);

module.exports = router;
