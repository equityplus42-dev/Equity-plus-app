const ApiResponse = require('../utils/apiResponse');
const logger = require('../utils/logger');

// eslint-disable-next-line no-unused-vars
function errorMiddleware(err, req, res, next) {
  logger.error(err.stack || err.message || err);

  const statusCode = err.statusCode || 500;
  const message = err.message || 'Internal Server Error';
  const errorCode = err.errorCode || 'SYS_001';

  return ApiResponse.error(res, message, statusCode, errorCode);
}

module.exports = errorMiddleware;
