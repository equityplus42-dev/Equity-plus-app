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

  /**
   * Public deferred referral lookup by client IP
   * GET /api/v1/referrals/deferred-lookup
   */
  async getDeferredReferral(req, res, next) {
    try {
      const rawIp = req.headers['x-real-ip'] || 
                    (req.headers['x-forwarded-for'] ? req.headers['x-forwarded-for'].split(',')[0] : null) || 
                    req.socket?.remoteAddress || 
                    req.ip || 
                    '127.0.0.1';
      const ipAddress = rawIp.toString().trim().replace(/^::ffff:/, '');

      const prisma = require('../config/database');
      let deferred = await prisma.deferredReferral.findFirst({
        where: {
          ipAddress,
          expiresAt: { gt: new Date() },
        },
        orderBy: { createdAt: 'desc' },
      });

      // Subnet fallback (/24) for cellular carrier network IP changes
      if (!deferred && ipAddress.includes('.')) {
        const ipParts = ipAddress.split('.');
        if (ipParts.length === 4) {
          const subnetPrefix = `${ipParts[0]}.${ipParts[1]}.${ipParts[2]}.`;
          deferred = await prisma.deferredReferral.findFirst({
            where: {
              ipAddress: { startsWith: subnetPrefix },
              expiresAt: { gt: new Date() },
            },
            orderBy: { createdAt: 'desc' },
          });
        }
      }

      if (!deferred) {
        return ApiResponse.success(res, 'No deferred referral found', { referralCode: null });
      }

      return ApiResponse.success(res, 'Deferred referral code retrieved', { referralCode: deferred.referralCode });
    } catch (error) {
      next(error);
    }
  }
}

module.exports = new ReferralController();
