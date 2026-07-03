const ApiResponse = require('../utils/apiResponse');
const { ROLES } = require('../config/constants');

function adminMiddleware(req, res, next) {
  if (!req.user) {
    return ApiResponse.error(res, 'Authentication required', 401);
  }

  if (req.user.role !== ROLES.ADMIN) {
    return ApiResponse.error(res, 'Access denied. Administrator privileges required.', 403);
  }

  next();
}

module.exports = adminMiddleware;
