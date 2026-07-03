const prisma = require('../config/database');

const uuidRegex = /^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$/i;
const isValidUUID = (str) => uuidRegex.test(str);

class UserSearchService {
  /**
   * Search for users strictly inside the requester's downline hierarchy
   * @param {string} loggedInUserId - Requester's user ID
   * @param {string} query - Name search query or exclusive UUID
   * @param {number} skip 
   * @param {number} take 
   */
  async searchVisibleHierarchy(loggedInUserId, query, skip = 0, take = 10) {
    // 1. Fetch searcher's hierarchy node
    const userNode = await prisma.hierarchyNode.findUnique({
      where: { userId: loggedInUserId },
    });

    if (!userNode) {
      return { users: [], total: 0 };
    }

    // 2. Build filter restricted to descendants (path starts with /parent-path/)
    const where = {
      role: 'USER',
      hierarchyNode: {
        path: {
          startsWith: `${userNode.path}/`,
        },
      },
    };

    // 3. Apply search filters
    if (query && query.trim().length > 0) {
      const q = query.trim();
      if (isValidUUID(q)) {
        where.id = q;
      } else {
        where.profile = {
          OR: [
            { firstName: { contains: q } },
            { lastName: { contains: q } },
          ],
        };
      }
    }

    const [users, total] = await Promise.all([
      prisma.user.findMany({
        where,
        skip,
        take,
        orderBy: { createdAt: 'desc' },
        include: {
          profile: true,
          hierarchyNode: true,
        },
      }),
      prisma.user.count({ where }),
    ]);

    return { users, total };
  }
}

module.exports = new UserSearchService();
