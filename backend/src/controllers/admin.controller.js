const userRepository = require('../repositories/user.repository');
const referralService = require('../services/referral.service');
const referralRepository = require('../repositories/referral.repository');
const settingsRepository = require('../repositories/settings.repository');
const prisma = require('../config/database');
const ApiResponse = require('../utils/apiResponse');
const auditLogService = require('../services/auditLog.service');

class AdminController {
  async getStats(req, res, next) {
    try {
      const totalUsers = await prisma.user.count({ where: { role: 'USER', isApproved: true } });
      const pendingApprovals = await prisma.referral.count({ where: { status: 'PENDING' } });
      const approvedReferrals = await prisma.referral.count({ where: { status: 'APPROVED' } });
      const totalReferrals = await prisma.referral.count();
      
      const pointsAgg = await prisma.user.aggregate({
        _sum: { points: true }
      });
      const totalPointsDistributed = pointsAgg._sum.points || 0;

      const recentSignups = await prisma.user.findMany({
        where: { role: 'USER', isApproved: true },
        take: 5,
        orderBy: { createdAt: 'desc' },
        include: { profile: true }
      });

      return ApiResponse.success(res, 'Admin statistics retrieved', {
        totalUsers,
        pendingApprovals,
        approvedReferrals,
        totalReferrals,
        totalPointsDistributed,
        recentSignups: recentSignups.map(({ password, ...u }) => u),
      });
    } catch (error) {
      next(error);
    }
  }

  async updateUserActiveStatus(req, res, next) {
    try {
      const { isActive } = req.body;
      const user = await userRepository.updateActiveStatus(req.params.userId, isActive);
      await auditLogService.log(req, isActive ? 'USER_ACTIVATE' : 'USER_SUSPEND', req.params.userId, { adminId: req.user.id });
      return ApiResponse.success(res, `User active status updated to ${isActive}`, user);
    } catch (error) {
      next(error);
    }
  }

  async getPendingReferrals(req, res, next) {
    try {
      const pending = await referralRepository.findAllPending();
      return ApiResponse.success(res, 'Pending referrals retrieved', pending);
    } catch (error) {
      next(error);
    }
  }

  async approveReferral(req, res, next) {
    try {
      const approved = await referralService.approveReferral(req.params.referralId);
      await auditLogService.log(req, 'REFERRAL_APPROVAL', approved.refereeId, { referralId: req.params.referralId, adminId: req.user.id });
      return ApiResponse.success(res, 'Referral reward approved successfully', approved);
    } catch (error) {
      next(error);
    }
  }

  async rejectReferral(req, res, next) {
    try {
      const rejected = await referralService.rejectReferral(req.params.referralId);
      await auditLogService.log(req, 'REFERRAL_REJECTION', rejected.refereeId, { referralId: req.params.referralId, adminId: req.user.id });
      return ApiResponse.success(res, 'Referral reward rejected successfully', rejected);
    } catch (error) {
      next(error);
    }
  }

  async updateSetting(req, res, next) {
    try {
      const { key, value, description } = req.body;
      if (!key || value === undefined) {
        return ApiResponse.error(res, 'Key and value are required', 400);
      }
      
      const setting = await settingsRepository.upsertSetting(key, String(value), description);
      await auditLogService.log(req, 'ADMIN_SETTINGS_UPDATE', null, { key, value, adminId: req.user.id });
      return ApiResponse.success(res, 'Setting updated successfully', setting);
    } catch (error) {
      next(error);
    }
  }

  async regenerateReferral(req, res, next) {
    try {
      const { userId } = req.params;
      const user = await userRepository.findById(userId);
      if (!user) {
        return ApiResponse.error(res, 'User not found', 404);
      }

      const generateCode = require('../services/referral/generateCode');
      const generateLink = require('../services/referral/generateLink');
      const { generateQR } = require('../services/qr.service');

      let uniqueReferralCode;
      let codeExists = true;
      while (codeExists) {
        uniqueReferralCode = generateCode(8);
        const checkedUser = await prisma.user.findUnique({
          where: { referralCode: uniqueReferralCode },
        });
        if (!checkedUser) {
          codeExists = false;
        }
      }

      const referralUrl = generateLink(uniqueReferralCode);
      const qrCode = await generateQR(referralUrl);

      const updatedUser = await prisma.user.update({
        where: { id: userId },
        data: {
          referralCode: uniqueReferralCode,
          referralUrl,
          qrCode,
        },
        include: { profile: true },
      });

      await auditLogService.log(req, 'REFERRAL_REGENERATE', userId, { adminId: req.user.id });

      const { password, ...sanitized } = updatedUser;
      return ApiResponse.success(res, 'User referral details regenerated', sanitized);
    } catch (error) {
      next(error);
    }
  }
}

module.exports = new AdminController();
