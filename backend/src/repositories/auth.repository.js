const prisma = require('../config/database');

class AuthRepository {
  async findByEmail(email) {
    return prisma.user.findUnique({
      where: { email },
      include: {
        profile: true,
      },
    });
  }

  async findByReferralCode(referralCode) {
    return prisma.user.findUnique({
      where: { referralCode },
      include: {
        hierarchyNode: true,
      },
    });
  }

  async createUser({ email, password, referralCode, referralUrl, qrCode, referrerId, firstName, lastName, phoneNumber }) {
    return prisma.user.create({
      data: {
        email,
        password,
        referralCode,
        referralUrl,
        qrCode,
        referrerId,
        profile: {
          create: {
            firstName,
            lastName,
            phoneNumber,
          },
        },
      },
      include: {
        profile: true,
      },
    });
  }
}

module.exports = new AuthRepository();
