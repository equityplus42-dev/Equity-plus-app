const logger = require('../../utils/logger');

/**
 * Simulate decoding of QR Code
 * @param {string} qrDataUrl 
 * @returns {Promise<Object>}
 */
async function decodeQR(qrDataUrl) {
  logger.info('Simulated decoding of QR Code');
  return { success: true, data: 'decoded-qr-data' };
}

module.exports = decodeQR;
