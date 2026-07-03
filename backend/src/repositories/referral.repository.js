const prisma = require('../config/database');

class ReferralRepository {
  async createReferral({ referrerId, refereeId, status, points }) {
    return prisma.referral.create({
      data: {
        referrerId,
        refereeId,
        status,
        points,
      },
      include: {
        referee: {
          select: {
            email: true,
            profile: true,
          },
        },
      },
    });
  }

  async findById(id) {
    return prisma.referral.findUnique({
      where: { id },
      include: {
        referrer: { select: { email: true, profile: true } },
        referee: { select: { email: true, profile: true } },
      },
    });
  }

  async findByRefereeId(refereeId) {
    return prisma.referral.findUnique({
      where: { refereeId },
    });
  }

  async findByReferrerId(referrerId) {
    return prisma.referral.findMany({
      where: { referrerId },
      include: {
        referee: {
          select: {
            id: true,
            email: true,
            createdAt: true,
            profile: {
              select: {
                firstName: true,
                lastName: true,
                avatarUrl: true,
              },
            },
          },
        },
      },
      orderBy: { createdAt: 'desc' },
    });
  }

  async updateStatus(id, status) {
    return prisma.referral.update({
      where: { id },
      data: { status },
      include: {
        referrer: true,
        referee: true,
      },
    });
  }

  async findAllPending() {
    return prisma.referral.findMany({
      where: { status: 'PENDING' },
      include: {
        referrer: { select: { id: true, email: true, profile: true } },
        referee: { select: { id: true, email: true, profile: true, createdAt: true } },
      },
      orderBy: { createdAt: 'desc' },
    });
  }

  async findAll({ skip, take }) {
    return prisma.referral.findMany({
      skip,
      take,
      include: {
        referrer: { select: { id: true, email: true, profile: true } },
        referee: { select: { id: true, email: true, profile: true } },
      },
      orderBy: { createdAt: 'desc' },
    });
  }

  async countAll() {
    return prisma.referral.count();
  }

  async getReferrerStats(userId) {
    const referrals = await prisma.referral.findMany({
      where: { referrerId: userId },
    });

    const totalReferrals = referrals.length;
    const approvedReferrals = referrals.filter(r => r.status === 'APPROVED').length;
    const totalPoints = referrals
      .filter(r => r.status === 'APPROVED')
      .reduce((sum, r) => sum + r.points, 0);

    return {
      totalReferrals,
      approvedReferrals,
      totalPoints,
    };
  }
}

module.exports = new ReferralRepository();
