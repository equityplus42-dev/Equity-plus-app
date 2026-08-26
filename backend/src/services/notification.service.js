const notificationRepository = require('../repositories/notification.repository');
const firebaseService = require('./firebase.service');
const logger = require('../utils/logger');

class NotificationService {
  async notifyReferralSignup(userId, refereeName, refereeId = null) {
    if (refereeId) {
      const prisma = require('../config/database');
      const referee = await prisma.user.findUnique({ where: { id: refereeId } });
      if (referee && (referee.isTestUser || referee.email === 'test@gmail.com')) {
        console.log(`[NotificationService] Skipping referral signup notification for test user (${referee.email}).`);
        return null;
      }
    }

    const title = 'New Referral Signup! 🎉';
    const message = `${refereeName} has signed up using your referral code.`;

    // 1. Create in-app DB notification
    const notification = await notificationRepository.createNotification({
      userId,
      title,
      message,
      type: 'REFERRAL_SIGNUP',
    });

    // 2. Dispatch FCM push notification asynchronously
    try {
      await firebaseService.sendPushNotification(userId, {
        title,
        body: message,
        data: { type: 'REFERRAL_SIGNUP', notificationId: notification.id },
      });
    } catch (err) {
      logger.error('Failed to send referral signup push notification', err);
    }

    return notification;
  }

  async notifyReferralApproved(userId, refereeName, points) {
    const title = 'Referral Reward Approved! 💰';
    const message = `Your referral of ${refereeName} was approved. You received +${points} points!`;

    // 1. Create in-app DB notification
    const notification = await notificationRepository.createNotification({
      userId,
      title,
      message,
      type: 'REFERRAL_APPROVED',
    });

    // 2. Dispatch FCM push notification
    try {
      await firebaseService.sendPushNotification(userId, {
        title,
        body: message,
        data: { type: 'REFERRAL_APPROVED', notificationId: notification.id },
      });
    } catch (err) {
      logger.error('Failed to send referral approval push notification', err);
    }

    return notification;
  }

  async notifyReferralRejected(userId, refereeName) {
    const title = 'Referral Reward Declined ❌';
    const message = `Your referral of ${refereeName} was not approved for rewards by the administrator.`;

    // 1. Create in-app DB notification
    const notification = await notificationRepository.createNotification({
      userId,
      title,
      message,
      type: 'REFERRAL_REJECTED',
    });

    // 2. Dispatch FCM push notification
    try {
      await firebaseService.sendPushNotification(userId, {
        title,
        body: message,
        data: { type: 'REFERRAL_REJECTED', notificationId: notification.id },
      });
    } catch (err) {
      logger.error('Failed to send referral rejection push notification', err);
    }

    return notification;
  }

  async notifySystemAlert(userId, title, message) {
    // 1. Create in-app DB notification
    const notification = await notificationRepository.createNotification({
      userId,
      title,
      message,
      type: 'SYSTEM',
    });

    // 2. Dispatch FCM push notification
    try {
      await firebaseService.sendPushNotification(userId, {
        title,
        body: message,
        data: { type: 'SYSTEM', notificationId: notification.id },
      });
    } catch (err) {
      logger.error('Failed to send system alert push notification', err);
    }

    return notification;
  }

  async notifyAdmins(title, message, type = 'SYSTEM', triggeringUserId = null) {
    const prisma = require('../config/database');
    try {
      if (triggeringUserId) {
        const user = await prisma.user.findUnique({ where: { id: triggeringUserId } });
        if (user && (user.isTestUser || user.email === 'test@gmail.com')) {
          console.log(`[NotificationService] Skipping admin notification for test user (${user.email}).`);
          return [];
        }
      }

      const admins = await prisma.user.findMany({
        where: { role: 'ADMIN', isDeleted: false },
        select: { id: true },
      });
      const notifications = await Promise.all(
        admins.map((admin) =>
          notificationRepository.createNotification({
            userId: admin.id,
            title,
            message,
            type,
          })
        )
      );
      return notifications;
    } catch (err) {
      logger.error('Failed to notify admins', err);
      return [];
    }
  }

  async getUserNotifications(userId) {
    return notificationRepository.findByUserId(userId);
  }

  async markAllRead(userId) {
    return notificationRepository.markAllAsRead(userId);
  }

  async markAsRead(notificationId) {
    return notificationRepository.markAsRead(notificationId);
  }

  /**
   * Delete all notifications for a specific user (self-clear).
   */
  async clearUserNotifications(userId) {
    return notificationRepository.deleteAllByUserId(userId);
  }

  /**
   * Delete EVERY notification in the system (admin action).
   */
  async clearAllNotifications() {
    return notificationRepository.deleteAllNotifications();
  }
}

module.exports = new NotificationService();
