const ApiResponse = require('../utils/apiResponse');
const { ROLES } = require('../config/constants');

function developerMiddleware(req, res, next) {
  if (!req.user) {
    return ApiResponse.error(res, 'Authentication required', 401);
  }

  if (req.user.role !== ROLES.DEVELOPER) {
    return ApiResponse.error(res, 'Access denied. Developer privileges required.', 403);
  }

  next();
}

module.exports = developerMiddleware;
