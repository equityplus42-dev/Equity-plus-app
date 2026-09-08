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
    const where = { isDeleted: false, isApproved: true, role: 'USER', isTestUser: false };
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
    const where = { isDeleted: false, isApproved: true, role: 'USER', isTestUser: false };
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

    const fullName = user.profile ? `${user.profile.firstName || ''} ${user.profile.lastName || ''}`.trim() : null;
    const notificationOrConditions = [
      { userId: id },
      { message: { contains: user.email } }
    ];
    if (fullName && fullName.length > 2) {
      notificationOrConditions.push({ message: { contains: fullName } });
    }

    // 1 & 2. Run clawback, archive log creation, and notification cleanup in parallel
    const referralService = require('../services/referral.service');
    await Promise.all([
      referralService.clawbackPointsOnUserDeletion(id).catch(err => {
        console.warn('[UserRepository] Non-fatal clawback notice:', err.message);
      }),
      prisma.deletedUserLog.create({
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
      }),
      prisma.notification.deleteMany({
        where: {
          OR: notificationOrConditions
        }
      }),
    ]);

    // 3. Delete user from database (cascades all foreign key relations natively in 1 DB operation)
    await prisma.user.delete({ where: { id } });

    return { id, email: user.email, deletedPermanently: true };
  }
}

module.exports = new UserRepository();
