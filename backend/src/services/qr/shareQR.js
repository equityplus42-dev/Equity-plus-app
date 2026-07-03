const logger = require('../../utils/logger');

/**
 * Simulate sharing of QR Code
 * @param {string} qrDataUrl 
 * @param {string} platform 
 * @returns {Promise<Object>}
 */
async function shareQR(qrDataUrl, platform) {
  logger.info('Simulated sharing of QR Code', { platform });
  return { success: true, platform };
}

module.exports = shareQR;
