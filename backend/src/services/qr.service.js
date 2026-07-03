const generateQR = require('./qr/generateQR');
const shareQR = require('./qr/shareQR');
const decodeQR = require('./qr/decodeQR');

/**
 * QR Code service aggregator keeping interface compatibility
 */
class QrService {
  async generateReferralQR(referralCode) {
    // Keep compatibility for legacy controllers if needed
    const referralLink = `https://referral-system.com/register?ref=${referralCode}`;
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
