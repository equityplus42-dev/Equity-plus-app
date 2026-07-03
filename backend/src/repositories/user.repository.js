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
    const where = { isDeleted: false };
    if (search) {
      where.OR = [
        { email: { contains: search, mode: 'insensitive' } },
        {
          profile: {
            OR: [
              { firstName: { contains: search, mode: 'insensitive' } },
              { lastName: { contains: search, mode: 'insensitive' } },
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
    const where = { isDeleted: false };
    if (search) {
      where.OR = [
        { email: { contains: search, mode: 'insensitive' } },
        {
          profile: {
            OR: [
              { firstName: { contains: search, mode: 'insensitive' } },
              { lastName: { contains: search, mode: 'insensitive' } },
            ],
          },
        },
      ];
    }

    return prisma.user.count({ where });
  }

  async updateApproval(id, isApproved) {
    return prisma.user.update({
      where: { id },
      data: { isApproved },
      include: { profile: true },
    });
  }

  async deleteUser(id) {
    return prisma.user.update({
      where: { id },
      data: {
        isDeleted: true,
        isActive: false,
        deletedAt: new Date()
      }
    });
  }
}

module.exports = new UserRepository();
