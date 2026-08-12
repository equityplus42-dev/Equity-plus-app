const ApiResponse = require('../utils/apiResponse');
const logger = require('../utils/logger');

// eslint-disable-next-line no-unused-vars
function errorMiddleware(err, req, res, next) {
  logger.error(err.stack || err.message || err);

  if (err.type === 'entity.too.large' || err.status === 413 || err.statusCode === 413) {
    return ApiResponse.error(
      res,
      'Payload Too Large: File or request payload exceeds the allowed limit (Max: 500MB).',
      413,
      'PAYLOAD_TOO_LARGE'
    );
  }

  const statusCode = err.statusCode || err.status || 500;
  const message = err.message || 'Internal Server Error';
  const errorCode = err.errorCode || 'SYS_001';

  return ApiResponse.error(res, message, statusCode, errorCode);
}

module.exports = errorMiddleware;
