const auditLogRepository = require('../repositories/auditLog.repository');
const logger = require('../utils/logger');

class AuditLogService {
  async log(req, action, userId = null, details = null) {
    try {
      const ipAddress = req.ip || req.headers['x-forwarded-for'] || req.socket.remoteAddress || null;
      const userAgent = req.headers['user-agent'] || null;

      // Extract userId from decoded token if available and not passed explicitly
      const resolvedUserId = userId || (req.user ? req.user.id : null);

      await auditLogRepository.createLog({
        userId: resolvedUserId,
        action,
        ipAddress,
        userAgent,
        details
      });
      logger.info(`[AuditLog] Action "${action}" recorded for User ID: ${resolvedUserId}`);
    } catch (error) {
      // Never crash critical requests due to audit log writing failures, just log the warning
      logger.warn(`[AuditLog] Failed to write action "${action}" log: ${error.message}`);
    }
  }
}

module.exports = new AuditLogService();
