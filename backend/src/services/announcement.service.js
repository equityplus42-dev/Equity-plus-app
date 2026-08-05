const prisma = require('../config/database');
const notificationService = require('./notification.service');

class AnnouncementService {
  async createAnnouncement({ title, message, targetType = 'ALL', targetId, scheduledAt, createdById }) {
    if (!title || !message) {
      throw new Error('Announcement title and message are required');
    }

    const announcement = await prisma.announcement.create({
      data: {
        title,
        message,
        targetType,
        targetId: targetId || null,
        scheduledAt: scheduledAt ? new Date(scheduledAt) : null,
        isSent: !scheduledAt,
        createdById: createdById || null,
      },
    });

    // If immediate (no scheduledAt), trigger broadcast notifications
    if (!scheduledAt) {
      await this.broadcastAnnouncement(announcement);
    }

    return announcement;
  }

  async broadcastAnnouncement(announcement) {
    const { title, message, targetType, targetId } = announcement;
    let targetUserIds = [];

    if (targetType === 'ALL') {
      const users = await prisma.user.findMany({
        where: { isApproved: true, isDeleted: false },
        select: { id: true },
      });
      targetUserIds = users.map((u) => u.id);
    } else if (targetType === 'USER' && targetId) {
      targetUserIds = [targetId];
    } else if (targetType === 'LANGUAGE' && targetId) {
      const profiles = await prisma.profile.findMany({
        where: { assignedLanguageId: targetId },
        select: { userId: true },
      });
      targetUserIds = profiles.map((p) => p.userId);
    } else if (targetType === 'PRODUCT' && targetId) {
      const profiles = await prisma.profile.findMany({
        where: { assignedProductId: targetId },
        select: { userId: true },
      });
      targetUserIds = profiles.map((p) => p.userId);
    }

    for (const uId of targetUserIds) {
      await notificationService.createNotification(
        uId,
        `📢 ${title}`,
        message,
        'ANNOUNCEMENT'
      );
    }

    await prisma.announcement.update({
      where: { id: announcement.id },
      data: { isSent: true },
    });
  }

  async getAdminAnnouncements() {
    return prisma.announcement.findMany({
      orderBy: { createdAt: 'desc' },
    });
  }

  async getUserAnnouncements(userId) {
    const user = await prisma.user.findUnique({
      where: { id: userId },
      include: { profile: true },
    });

    if (!user) return [];

    const langId = user.profile?.assignedLanguageId;
    const prodId = user.profile?.assignedProductId;

    const conditions = [{ targetType: 'ALL' }, { targetType: 'USER', targetId: userId }];
    if (langId) conditions.push({ targetType: 'LANGUAGE', targetId: langId });
    if (prodId) conditions.push({ targetType: 'PRODUCT', targetId: prodId });

    return prisma.announcement.findMany({
      where: {
        isSent: true,
        OR: conditions,
      },
      orderBy: { createdAt: 'desc' },
      take: 10,
    });
  }
}

module.exports = new AnnouncementService();
