const prisma = require('../config/database');

class HierarchyRepository {
  async createNode({ userId, parentId, path, level }) {
    return prisma.hierarchyNode.create({
      data: {
        userId,
        parentId,
        path,
        level,
      },
      include: {
        user: {
          select: {
            email: true,
            profile: true,
          },
        },
      },
    });
  }

  async findByUserId(userId) {
    return prisma.hierarchyNode.findUnique({
      where: { userId },
      include: {
        user: {
          select: {
            email: true,
            profile: true,
          },
        },
      },
    });
  }

  /**
   * Find descendants of a node by path matching (like a subtree)
   * @param {string} userPath - Path prefix of the user
   * @param {number} maxLevel - Optional depth filter
   */
  async findDescendants(userPath, maxLevel) {
    const where = {
      path: {
        startsWith: `${userPath}/`,
      },
    };

    if (maxLevel !== undefined) {
      where.level = {
        lte: maxLevel,
      };
    }

    return prisma.hierarchyNode.findMany({
      where,
      include: {
        user: {
          select: {
            email: true,
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
      orderBy: { level: 'asc' },
    });
  }

  async findAllNodes() {
    return prisma.hierarchyNode.findMany({
      include: {
        user: {
          select: {
            email: true,
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
      orderBy: { level: 'asc' },
    });
  }
}

module.exports = new HierarchyRepository();
