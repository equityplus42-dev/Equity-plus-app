const logger = require('../utils/logger');

class FirebaseService {
  /**
   * Send simulated push notification via FCM
   * @param {string} userId - Target recipient user ID
   * @param {Object} payload - { title, body, data }
   * @returns {Promise<Object>} - FCM message delivery response
   */
  async sendPushNotification(userId, { title, body, data }) {
    logger.info('Simulated Firebase Cloud Messaging push notification', {
      userId,
      title,
      body,
      data,
    });
    return {
      success: true,
      messageId: `simulated-fcm-msg-${Date.now()}-${Math.floor(Math.random() * 1000)}`,
    };
  }
}

module.exports = new FirebaseService();
