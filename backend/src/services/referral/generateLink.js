const env = require('../../config/env');

/**
 * Generate a referral URL for a given referral code
 * Format: https://YOUR_DOMAIN/r/REFERRAL_CODE
 * @param {string} referralCode 
 * @returns {string}
 */
function generateLink(referralCode) {
  const domain = env.APP_DOMAIN || 'referral-system.com';
  return `https://${domain}/r/${referralCode}`;
}

module.exports = generateLink;
