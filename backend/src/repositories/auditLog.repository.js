const prisma = require('../config/database');

class AuditLogRepository {
  async createLog({ userId, action, ipAddress, userAgent, details }) {
    let validUserId = null;
    if (userId) {
      const userExists = await prisma.user.findUnique({ where: { id: userId }, select: { id: true } });
      if (userExists) validUserId = userId;
    }
    return prisma.auditLog.create({
      data: {
        userId: validUserId,
        action,
        ipAddress,
        userAgent,
        details: details ? (typeof details === 'object' ? JSON.stringify(details) : details) : null
      }
    });
  }

  async findLogsByUser(userId) {
    return prisma.auditLog.findMany({
      where: { userId },
      orderBy: { createdAt: 'desc' }
    });
  }
}

module.exports = new AuditLogRepository();
