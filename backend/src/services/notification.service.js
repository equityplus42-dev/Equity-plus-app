const notificationRepository = require('../repositories/notification.repository');
const firebaseService = require('./firebase.service');
const logger = require('../utils/logger');

class NotificationService {
  async notifyReferralSignup(userId, refereeName) {
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

  async getUserNotifications(userId) {
    return notificationRepository.findByUserId(userId);
  }

  async markAllRead(userId) {
    return notificationRepository.markAllAsRead(userId);
  }

  async markAsRead(notificationId) {
    return notificationRepository.markAsRead(notificationId);
  }
}

module.exports = new NotificationService();
