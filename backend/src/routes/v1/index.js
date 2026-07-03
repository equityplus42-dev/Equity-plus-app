const express = require('express');
const router = express.Router();

const authRoutes = require('./auth.routes');
const userRoutes = require('./user.routes');
const adminRoutes = require('./admin.routes');
const profileRoutes = require('./profile.routes');
const referralRoutes = require('./referral.routes');
const hierarchyRoutes = require('./hierarchy.routes');
const notificationRoutes = require('./notification.routes');
const searchRoutes = require('./search.routes');
const settingsRoutes = require('./settings.routes');

router.use('/auth', authRoutes);
router.use('/users', userRoutes);
router.use('/admin', adminRoutes);
router.use('/profile', profileRoutes);
router.use('/referrals', referralRoutes);
router.use('/hierarchy', hierarchyRoutes);
router.use('/notifications', notificationRoutes);
const prisma = require('../../config/database');

router.get('/health', async (req, res) => {
  try {
    await prisma.$queryRaw`SELECT 1`;
    return res.status(200).json({
      success: true,
      message: "Server running",
      version: "1.0.0",
      database: "Connected"
    });
  } catch (error) {
    return res.status(500).json({
      success: false,
      message: "Server running with database issues",
      version: "1.0.0",
      database: "Disconnected"
    });
  }
});

router.use('/search', searchRoutes);
router.use('/settings', settingsRoutes);

module.exports = router;
