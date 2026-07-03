const prisma = require('../config/database');

class AuditLogRepository {
  async createLog({ userId, action, ipAddress, userAgent, details }) {
    return prisma.auditLog.create({
      data: {
        userId,
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
