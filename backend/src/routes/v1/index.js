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
const languageRoutes = require('./language.routes');
const videoRoutes = require('./video.routes');
const languageRequestRoutes = require('./languageRequest.routes');
const productRoutes = require('./product.routes');
const videoVersionRoutes = require('./videoVersion.routes');
const playbackSessionRoutes = require('./playbackSession.routes');
const videoAnalyticsRoutes = require('./videoAnalytics.routes');
const announcementRoutes = require('./announcement.routes');
const uploadPipelineRoutes = require('./uploadPipeline.routes');
const paymentRoutes = require('./payment.routes');
const refundRoutes = require('./refund.routes');
const videoAssignmentRoutes = require('./videoAssignment.routes');
const appReleaseRoutes = require('./appRelease.routes');
const appVersionMiddleware = require('../../middleware/appVersion.middleware');

router.use('/app-version', appReleaseRoutes);
router.use(appVersionMiddleware);

router.use('/auth', authRoutes);
router.use('/users', userRoutes);
router.use('/admin', adminRoutes);
router.use('/profile', profileRoutes);
router.use('/referrals', referralRoutes);
router.use('/hierarchy', hierarchyRoutes);
router.use('/notifications', notificationRoutes);
router.use('/languages', languageRoutes);
router.use('/videos', videoRoutes);
router.use('/language-requests', languageRequestRoutes);
router.use('/products', productRoutes);
router.use('/versions', videoVersionRoutes);
router.use('/sessions', playbackSessionRoutes);
router.use('/analytics', videoAnalyticsRoutes);
router.use('/announcements', announcementRoutes);
router.use('/upload-pipeline', uploadPipelineRoutes);
router.use('/payments', paymentRoutes);
router.use('/refunds', refundRoutes);
router.use('/admin/video-assignments', videoAssignmentRoutes);
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
