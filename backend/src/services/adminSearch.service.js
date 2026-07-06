const prisma = require('../config/database');

const uuidRegex = /^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$/i;
const isValidUUID = (str) => uuidRegex.test(str);

class AdminSearchService {
  /**
   * Search globally across all users in the system
   * @param {string} query - Query containing email, code, name, mobile, or UUID
   * @param {number} skip 
   * @param {number} take 
   */
  async searchGlobal(query, skip = 0, take = 10) {
    const where = {};

    if (query && query.trim().length > 0) {
      const q = query.trim();
      
      const orConditions = [
        { email: { contains: q } },
        { referralCode: { contains: q } },
        {
          profile: {
            OR: [
              { firstName: { contains: q } },
              { lastName: { contains: q } },
              { phoneNumber: { contains: q } },
              { panNumber: { contains: q } },
            ],
          },
        },
      ];

      if (isValidUUID(q)) {
        orConditions.push({ id: q });
      }

      where.OR = orConditions;
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

module.exports = new AdminSearchService();
