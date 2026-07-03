const referralRepository = require('../repositories/referral.repository');
const authRepository = require('../repositories/auth.repository');
const hierarchyRepository = require('../repositories/hierarchy.repository');
const settingsRepository = require('../repositories/settings.repository');
const notificationService = require('./notification.service');
const hierarchyService = require('./hierarchy.service');
const prisma = require('../config/database');
const { SETTINGS_KEYS, DEFAULT_SETTINGS } = require('../config/constants');
const { getAncestorsFromPath } = require('../utils/hierarchyHelper');

class ReferralService {
  /**
   * Validate if a referral code exists
   * @param {string} code 
   */
  async validateReferralCode(code) {
    if (!code) return null;
    const referrer = await authRepository.findByReferralCode(code);
    if (!referrer) {
      throw new Error('Invalid referral code');
    }
    return referrer;
  }

  /**
   * Create a new referral signup record
   * @param {string} refereeId 
   * @param {string} referrerId 
   */
  async createReferralEntry(refereeId, referrerId) {
    // 1. Fetch system settings
    const settings = await this.getSystemSettings();
    const requireApproval = settings[SETTINGS_KEYS.REQUIRE_APPROVAL] === 'true';
    const l1Points = parseInt(settings[SETTINGS_KEYS.POINTS_L1], 10) || DEFAULT_SETTINGS.points_level_1;

    // 2. Determine initial status
    const status = requireApproval ? 'PENDING' : 'APPROVED';

    // 3. Create referral record in database
    const referral = await referralRepository.createReferral({
      referrerId,
      refereeId,
      status,
      points: l1Points, // direct points
    });

    // 4. Send initial signup notification to referrer
    const refereeUser = await prisma.user.findUnique({
      where: { id: refereeId },
      include: { profile: true }
    });
    const refereeName = refereeUser?.profile 
      ? `${refereeUser.profile.firstName || ''} ${refereeUser.profile.lastName || ''}`.trim() 
      : refereeUser.email;

    await notificationService.notifyReferralSignup(referrerId, refereeName);

    // 5. If auto-approved, distribute points immediately
    if (status === 'APPROVED') {
      await this.distributePoints(refereeId, refereeName, settings);
    }

    return referral;
  }

  /**
   * Approve a pending referral
   * @param {string} referralId 
   */
  async approveReferral(referralId) {
    const referral = await referralRepository.findById(referralId);
    if (!referral) {
      throw new Error('Referral record not found');
    }

    if (referral.status === 'APPROVED') {
      throw new Error('Referral is already approved');
    }

    // Update status to APPROVED
    const updated = await referralRepository.updateStatus(referralId, 'APPROVED');

    // **Approve the User & Add to Hierarchy**
    await prisma.user.update({
      where: { id: referral.refereeId },
      data: { isApproved: true }
    });
    
    await hierarchyService.createNodeForUser(referral.refereeId, referral.referrerId);

    const refereeName = referral.referee.profile 
      ? `${referral.referee.profile.firstName || ''} ${referral.referee.profile.lastName || ''}`.trim() 
      : referral.referee.email;

    // Distribute points to all levels
    const settings = await this.getSystemSettings();
    await this.distributePoints(referral.refereeId, refereeName, settings);

    return updated;
  }

  /**
   * Reject a pending referral
   * @param {string} referralId 
   */
  async rejectReferral(referralId) {
    const referral = await referralRepository.findById(referralId);
    if (!referral) {
      throw new Error('Referral record not found');
    }

    if (referral.status !== 'PENDING') {
      throw new Error('Can only reject pending referrals');
    }

    const updated = await referralRepository.updateStatus(referralId, 'REJECTED');

    const refereeName = referral.referee.profile 
      ? `${referral.referee.profile.firstName || ''} ${referral.referee.profile.lastName || ''}`.trim() 
      : referral.referee.email;

    // Notify referrer of rejection
    await notificationService.notifyReferralRejected(referral.referrerId, refereeName);

    return updated;
  }

  /**
   * Distribute referral points up the hierarchy chain
   * @param {string} refereeId 
   * @param {string} refereeName 
   * @param {Object} settings 
   */
  async distributePoints(refereeId, refereeName, settings) {
    const node = await hierarchyRepository.findByUserId(refereeId);
    if (!node) return;

    // Get ancestor user IDs from path: e.g. ["A", "B", "C"] (A is root, C is direct parent)
    const ancestors = getAncestorsFromPath(node.path);
    // Reverse to walk upwards: ["C", "B", "A"] (C=Level 1, B=Level 2, A=Level 3)
    const reversedAncestors = [...ancestors].reverse();

    const maxDepth = parseInt(settings[SETTINGS_KEYS.MAX_DEPTH], 10) || DEFAULT_SETTINGS.max_hierarchy_depth;
    
    // Points config
    const pointsMap = {
      1: parseInt(settings[SETTINGS_KEYS.POINTS_L1], 10) || DEFAULT_SETTINGS.points_level_1,
      2: parseInt(settings[SETTINGS_KEYS.POINTS_L2], 10) || DEFAULT_SETTINGS.points_level_2,
      3: parseInt(settings[SETTINGS_KEYS.POINTS_L3], 10) || DEFAULT_SETTINGS.points_level_3,
    };

    // Distribute rewards up to the max depth
    const limit = Math.min(reversedAncestors.length, maxDepth);
    for (let i = 0; i < limit; i++) {
      const ancestorId = reversedAncestors[i];
      const level = i + 1;
      const points = pointsMap[level] || 0;

      if (points > 0) {
        // Increment user's point balance
        await prisma.user.update({
          where: { id: ancestorId },
          data: { points: { increment: points } },
        });

        // Notify the user of points earned
        if (level === 1) {
          await notificationService.notifyReferralApproved(ancestorId, refereeName, points);
        } else {
          await notificationService.notifySystemAlert(
            ancestorId,
            `Indirect Reward! Level ${level} 💰`,
            `An indirect referral (${refereeName}) joined your network at Level ${level}. You earned +${points} points!`
          );
        }
      }
    }
  }

  /**
   * Retrieve active configuration key-values
   */
  async getSystemSettings() {
    const records = await settingsRepository.getSettings();
    const settingsObj = {};
    
    // Load defaults
    Object.keys(DEFAULT_SETTINGS).forEach((key) => {
      settingsObj[key] = String(DEFAULT_SETTINGS[key]);
    });

    // Override with DB values
    records.forEach((record) => {
      settingsObj[record.key] = record.value;
    });

    return settingsObj;
  }
}

module.exports = new ReferralService();
