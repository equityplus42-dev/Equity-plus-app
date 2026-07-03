const logger = require('../../utils/logger');

/**
 * Simulate sharing of a referral link
 * @param {string} referralLink 
 * @param {string} platform 
 * @returns {Promise<Object>}
 */
async function shareLink(referralLink, platform) {
  logger.info('Simulated sharing of referral link', { platform });
  return { success: true, platform };
}

module.exports = shareLink;
