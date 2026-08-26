const prisma = require('../config/database');

class UserRepository {
  async findById(id) {
    return prisma.user.findUnique({
      where: { id },
      include: {
        profile: true,
        hierarchyNode: true,
        referrer: {
          select: {
            id: true,
            email: true,
            profile: {
              select: {
                firstName: true,
                lastName: true,
              },
            },
          },
        },
      },
    });
  }

  async findAll({ skip, take, search }) {
    const where = { isDeleted: false, isApproved: true, role: 'USER' };
    if (search) {
      where.OR = [
        { id: { contains: search } },
        { email: { contains: search } },
        { referralCode: { contains: search } },
        {
          profile: {
            OR: [
              { firstName: { contains: search } },
              { lastName: { contains: search } },
              { phoneNumber: { contains: search } },
              { panNumber: { contains: search } },
            ],
          },
        },
      ];
    }

    return prisma.user.findMany({
      where,
      skip,
      take,
      orderBy: { createdAt: 'desc' },
      include: {
        profile: true,
        hierarchyNode: true,
      },
    });
  }

  async countAll({ search }) {
    const where = { isDeleted: false, isApproved: true, role: 'USER' };
    if (search) {
      where.OR = [
        { id: { contains: search } },
        { email: { contains: search } },
        { referralCode: { contains: search } },
        {
          profile: {
            OR: [
              { firstName: { contains: search } },
              { lastName: { contains: search } },
              { phoneNumber: { contains: search } },
              { panNumber: { contains: search } },
            ],
          },
        },
      ];
    }

    return prisma.user.count({ where });
  }

  async updateActiveStatus(id, isActive) {
    return prisma.user.update({
      where: { id },
      data: { isActive },
      include: { profile: true },
    });
  }

  async deleteUser(id, adminId = 'ADMIN') {
    const user = await prisma.user.findUnique({
      where: { id },
      include: {
        profile: true,
        hierarchyNode: true,
        payments: true,
        productAccesses: true,
      },
    });

    if (!user) {
      return null;
    }

    // 1. Save user details to DeletedUserLog table
    await prisma.deletedUserLog.create({
      data: {
        userId: user.id,
        email: user.email,
        role: user.role,
        referralCode: user.referralCode,
        referrerId: user.referrerId,
        firstName: user.profile?.firstName || null,
        lastName: user.profile?.lastName || null,
        phoneNumber: user.profile?.phoneNumber || null,
        whatsApp: user.profile?.whatsApp || null,
        state: user.profile?.state || null,
        district: user.profile?.district || null,
        panNumber: user.profile?.panNumber || null,
        aadharNumber: user.profile?.aadharNumber || null,
        assignedLanguageId: user.profile?.assignedLanguageId || null,
        assignedProductId: user.profile?.assignedProductId || null,
        points: user.points || 0,
        deletedBy: adminId,
        snapshotData: JSON.stringify(user),
      },
    });

    // 2. Permanently hard delete user from main active User table and clean up child records
    await prisma.$transaction([
      prisma.userVideoProgress.deleteMany({ where: { userId: id } }),
      prisma.snapshotVideo.deleteMany({ where: { snapshot: { userId: id } } }),
      prisma.userVideoSnapshot.deleteMany({ where: { userId: id } }),
      prisma.languageChangeRequest.deleteMany({ where: { userId: id } }),
      prisma.playbackSession.deleteMany({ where: { userId: id } }),
      prisma.notification.deleteMany({ where: { userId: id } }),
      prisma.referral.deleteMany({ where: { OR: [{ refereeId: id }, { referrerId: id }] } }),
      prisma.hierarchyNode.deleteMany({ where: { userId: id } }),
      prisma.userProductAccess.deleteMany({ where: { userId: id } }),
      prisma.videoAssignment.deleteMany({ where: { userId: id } }),
      prisma.profile.deleteMany({ where: { userId: id } }),
      prisma.user.delete({ where: { id } }),
    ]);

    return { id, email: user.email, deletedPermanently: true };
  }
}

module.exports = new UserRepository();
