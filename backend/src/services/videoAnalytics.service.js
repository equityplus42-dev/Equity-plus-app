const prisma = require('../config/database');

class VideoAnalyticsService {
  async getVideoAnalytics(videoId) {
    const video = await prisma.video.findUnique({
      where: { id: videoId },
      include: { language: true, product: true },
    });

    if (!video) {
      throw new Error('Video not found');
    }

    const assignedSnapshotsCount = await prisma.snapshotVideo.count({
      where: { videoId },
    });

    const progressRecords = await prisma.userVideoProgress.findMany({
      where: { videoId },
    });

    const usersStarted = progressRecords.length;
    const usersCompleted = progressRecords.filter((p) => p.isCompleted).length;
    const usersWatching = Math.max(0, usersStarted - usersCompleted);

    let totalWatchSecs = 0;
    for (const p of progressRecords) {
      totalWatchSecs += p.watchedSecs;
    }

    const avgWatchTimeSecs = usersStarted > 0 ? Math.round(totalWatchSecs / usersStarted) : 0;
    const duration = video.duration || 1;
    const avgWatchPercentage = Math.min(100, Math.round(((avgWatchTimeSecs / duration) * 100) * 100) / 100);

    // Calculate views in last 24h, 7d, 30d
    const now = new Date();
    const oneDayAgo = new Date(now.getTime() - 24 * 60 * 60 * 1000);
    const sevenDaysAgo = new Date(now.getTime() - 7 * 24 * 60 * 60 * 1000);
    const thirtyDaysAgo = new Date(now.getTime() - 30 * 24 * 60 * 60 * 1000);

    const dailyViews = await prisma.playbackSession.count({
      where: { videoId, startedAt: { gte: oneDayAgo } },
    });

    const weeklyViews = await prisma.playbackSession.count({
      where: { videoId, startedAt: { gte: sevenDaysAgo } },
    });

    const monthlyViews = await prisma.playbackSession.count({
      where: { videoId, startedAt: { gte: thirtyDaysAgo } },
    });

    return {
      videoId: video.id,
      title: video.title,
      languageName: video.language.name,
      productName: video.product?.name || 'General',
      durationSeconds: video.duration,
      usersAssigned: assignedSnapshotsCount,
      usersStarted,
      usersWatching,
      usersCompleted,
      avgWatchPercentage,
      avgWatchTimeSecs,
      dailyViews,
      weeklyViews,
      monthlyViews,
    };
  }

  async getGlobalVideoAnalytics() {
    const totalVideos = await prisma.video.count({ where: { isActive: true } });
    const totalSnapshots = await prisma.userVideoSnapshot.count();
    const totalSessions = await prisma.playbackSession.count();

    // Most active language
    const langStats = await prisma.userVideoSnapshot.groupBy({
      by: ['languageId'],
      _count: { languageId: true },
      orderBy: { _count: { languageId: 'desc' } },
      take: 1,
    });

    let mostActiveLanguage = 'English';
    if (langStats.length > 0) {
      const l = await prisma.language.findUnique({ where: { id: langStats[0].languageId } });
      if (l) mostActiveLanguage = l.name;
    }

    // Most active product
    const prodStats = await prisma.profile.groupBy({
      by: ['assignedProductId'],
      _count: { assignedProductId: true },
      where: { assignedProductId: { not: null } },
      orderBy: { _count: { assignedProductId: 'desc' } },
      take: 1,
    });

    let mostActiveProduct = 'General Course';
    if (prodStats.length > 0 && prodStats[0].assignedProductId) {
      const p = await prisma.product.findUnique({ where: { id: prodStats[0].assignedProductId } });
      if (p) mostActiveProduct = p.name;
    }

    const totalRefundIneligibleSnapshots = await prisma.userVideoSnapshot.count({
      where: { refundEligible: false },
    });

    return {
      totalActiveVideos: totalVideos,
      totalUserSnapshots: totalSnapshots,
      totalPlaybackSessions: totalSessions,
      mostActiveLanguage,
      mostActiveProduct,
      totalRefundIneligibleSnapshots,
    };
  }
}

module.exports = new VideoAnalyticsService();
