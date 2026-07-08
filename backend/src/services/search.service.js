const userRepository = require('../repositories/user.repository');
const prisma = require('../config/database');

class SearchService {
  /**
   * Search for users by email, name, or referral code
   * @param {string} query 
   * @param {number} skip 
   * @param {number} take 
   */
  async searchUsers(query, skip = 0, take = 10) {
    if (!query) {
      return userRepository.findAll({ skip, take });
    }

    const where = {
      OR: [
        { id: { contains: query } },
        { email: { contains: query } },
        { referralCode: { contains: query } },
        {
          profile: {
            OR: [
              { firstName: { contains: query } },
              { lastName: { contains: query } },
            ],
          },
        },
      ],
    };

    const users = await prisma.user.findMany({
      where,
      skip,
      take,
      orderBy: { createdAt: 'desc' },
      include: {
        profile: true,
        hierarchyNode: true,
      },
    });

    const total = await prisma.user.count({ where });

    return { users, total };
  }
}

module.exports = new SearchService();
