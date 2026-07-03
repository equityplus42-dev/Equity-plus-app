const { info } = require('../utils/logger');

/**
 * Express middleware to log details of HTTP requests
 */
function loggerMiddleware(req, res, next) {
  const start = Date.now();
  res.on('finish', () => {
    const duration = Date.now() - start;
    info('Request Processed', {
      method: req.method,
      url: req.originalUrl,
      status: res.statusCode,
      durationMs: duration,
      ip: req.ip || req.connection.remoteAddress,
      userAgent: req.get('User-Agent'),
    });
  });
  next();
}

module.exports = loggerMiddleware;
