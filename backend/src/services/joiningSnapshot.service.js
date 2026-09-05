const prisma = require('../config/database');
const notificationService = require('./notification.service');

class JoiningSnapshotService {
  /**
   * Create a permanent UserJoiningSnapshot when a new user registers
   */
  async createSnapshotForUser(userId) {
    try {
      const user = await prisma.user.findUnique({
        where: { id: userId },
        include: {
          profile: { include: { assignedLanguage: true } },
          referrer: { include: { profile: true } },
          hierarchyNode: true,
        },
      });

      if (!user) return null;

      const userName = user.profile
        ? `${user.profile.firstName || ''} ${user.profile.lastName || ''}`.trim() || user.email
        : user.email;

      const referrerName = user.referrer?.profile
        ? `${user.referrer.profile.firstName || ''} ${user.referrer.profile.lastName || ''}`.trim() || user.referrer.email
        : user.referrer?.email || null;

      const snapshot = await prisma.userJoiningSnapshot.upsert({
        where: { userId: user.id },
        update: {
          userEmail: user.email,
          userName,
          phoneNumber: user.profile?.phoneNumber || null,
          joinedAt: user.createdAt,
          referralCodeUsed: user.referralCode || 'N/A',
          referrerId: user.referrerId || null,
          referrerName,
          referrerEmail: user.referrer?.email || null,
          assignedLanguageName: user.profile?.assignedLanguage?.name || 'General',
          hierarchyLevel: user.hierarchyNode?.level || 0,
        },
        create: {
          userId: user.id,
          userEmail: user.email,
          userName,
          phoneNumber: user.profile?.phoneNumber || null,
          joinedAt: user.createdAt,
          referralCodeUsed: user.referralCode || 'N/A',
          referrerId: user.referrerId || null,
          referrerName,
          referrerEmail: user.referrer?.email || null,
          assignedLanguageName: user.profile?.assignedLanguage?.name || 'General',
          hierarchyLevel: user.hierarchyNode?.level || 0,
        },
      });

      // Notify Admins about the new user joining (Only for regular USER registrations)
      if (user.role === 'USER' && !user.isTestUser && user.email !== 'test@gmail.com') {
        const joinMsg = `New User Registered: "${userName}" (${user.email}) joined on ${new Date(user.createdAt).toLocaleDateString()} using referral code ${user.referralCode || 'N/A'}${referrerName ? ` (Referred by ${referrerName})` : ''}.`;
        await notificationService.notifyAdmins('New User Joined! 👤', joinMsg, 'USER_JOINED', user.id);
      }

      return snapshot;
    } catch (err) {
      console.error('[JoiningSnapshotService] Error creating user joining snapshot:', err.message);
      return null;
    }
  }

  /**
   * Get all User Joining Snapshots (Developer Only)
   */
  async getAllJoiningSnapshots({ search, page = 1, limit = 50 }) {
    const skip = (parseInt(page, 10) - 1) * parseInt(limit, 10);
    const take = parseInt(limit, 10);

    const where = {};
    if (search && search.trim().length > 0) {
      const q = search.trim();
      where.OR = [
        { userName: { contains: q, mode: 'insensitive' } },
        { userEmail: { contains: q, mode: 'insensitive' } },
        { referralCodeUsed: { contains: q, mode: 'insensitive' } },
        { referrerName: { contains: q, mode: 'insensitive' } },
        { referrerEmail: { contains: q, mode: 'insensitive' } },
      ];
    }

    const [total, snapshots] = await Promise.all([
      prisma.userJoiningSnapshot.count({ where }),
      prisma.userJoiningSnapshot.findMany({
        where,
        orderBy: { joinedAt: 'desc' },
        skip,
        take,
      }),
    ]);

    return {
      total,
      page: parseInt(page, 10),
      totalPages: Math.ceil(total / take) || 1,
      snapshots,
    };
  }
}

module.exports = new JoiningSnapshotService();
