const QRCode = require('qrcode');
const logger = require('../../utils/logger');

/**
 * Generate a QR Code as a Data URL (base64 string)
 * @param {string} text 
 * @returns {Promise<string>}
 */
async function generateQR(text) {
  try {
    const dataUrl = await QRCode.toDataURL(text, {
      errorCorrectionLevel: 'H',
      margin: 1,
      width: 300,
      color: {
        dark: '#000000',
        light: '#FFFFFF'
      }
    });
    return dataUrl;
  } catch (err) {
    logger.error('Error generating QR Code', err);
    throw new Error('Failed to generate QR Code');
  }
}

module.exports = generateQR;
