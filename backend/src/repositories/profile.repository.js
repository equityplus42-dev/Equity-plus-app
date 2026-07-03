const prisma = require('../config/database');

class ProfileRepository {
  async update(userId, data) {
    return prisma.profile.update({
      where: { userId },
      data,
    });
  }
}

module.exports = new ProfileRepository();
