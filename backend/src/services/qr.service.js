const generateQR = require('./qr/generateQR');
const shareQR = require('./qr/shareQR');
const decodeQR = require('./qr/decodeQR');

/**
 * QR Code service aggregator keeping interface compatibility
 */
class QrService {
  async generateReferralQR(referralCode) {
    const env = require('../config/env');
    const domain = env.APP_DOMAIN || 'vridhi-network-app.vercel.app';
    const referralLink = `https://${domain}/download?ref=${referralCode}`;
    return generateQR(referralLink);
  }
}

const qrService = new QrService();

module.exports = {
  generateQR,
  shareQR,
  decodeQR,
  generateReferralQR: qrService.generateReferralQR,
};
