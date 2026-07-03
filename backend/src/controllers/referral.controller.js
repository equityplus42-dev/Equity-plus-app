const referralRepository = require('../repositories/referral.repository');
const qrService = require('../services/qr.service');
const userRepository = require('../repositories/user.repository');
const ApiResponse = require('../utils/apiResponse');

class ReferralController {
  async getReferrals(req, res, next) {
    try {
      const referrals = await referralRepository.findByReferrerId(req.user.id);
      return ApiResponse.success(res, 'Referrals list retrieved', referrals);
    } catch (error) {
      next(error);
    }
  }

  async getStats(req, res, next) {
    try {
      const stats = await referralRepository.getReferrerStats(req.user.id);
      return ApiResponse.success(res, 'Referral statistics retrieved', stats);
    } catch (error) {
      next(error);
    }
  }

  async getReferralQR(req, res, next) {
    try {
      const user = await userRepository.findById(req.user.id);
      if (!user) {
        return ApiResponse.error(res, 'User not found', 404);
      }
      
      let qrCode = user.qrCode;
      let referralUrl = user.referralUrl;

      if (!qrCode || !referralUrl) {
        const generateLink = require('../services/referral/generateLink');
        const { generateQR } = require('../services/qr.service');
        const prisma = require('../config/database');
        
        referralUrl = referralUrl || generateLink(user.referralCode);
        qrCode = qrCode || await generateQR(referralUrl);

        // Update database for subsequent retrievals
        await prisma.user.update({
          where: { id: user.id },
          data: { qrCode, referralUrl },
        });
      }
      
      return ApiResponse.success(res, 'QR Code retrieved', { 
        qrCode, 
        referralCode: user.referralCode,
        referralUrl
      });
    } catch (error) {
      next(error);
    }
  }
}

module.exports = new ReferralController();
