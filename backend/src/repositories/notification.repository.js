const prisma = require('../config/database');

class NotificationRepository {
  async createNotification({ userId, title, message, type }) {
    return prisma.notification.create({
      data: {
        userId,
        title,
        message,
        type,
      },
    });
  }

  async findByUserId(userId) {
    return prisma.notification.findMany({
      where: { userId },
      orderBy: { createdAt: 'desc' },
    });
  }

  async markAsRead(id) {
    return prisma.notification.update({
      where: { id },
      data: { isRead: true },
    });
  }

  async markAllAsRead(userId) {
    return prisma.notification.updateMany({
      where: { userId, isRead: false },
      data: { isRead: true },
    });
  }

  async deleteAllByUserId(userId) {
    return prisma.notification.deleteMany({ where: { userId } });
  }

  async deleteAllNotifications() {
    return prisma.notification.deleteMany({});
  }
}

module.exports = new NotificationRepository();
