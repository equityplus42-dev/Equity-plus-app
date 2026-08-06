const ApiResponse = require('../utils/apiResponse');

function roleMiddleware(allowedRoles = []) {
  const roles = Array.isArray(allowedRoles) ? allowedRoles : [allowedRoles];

  return (req, res, next) => {
    if (!req.user) {
      return ApiResponse.error(res, 'Authentication required', 401);
    }

    if (roles.length > 0 && !roles.includes(req.user.role)) {
      return ApiResponse.error(res, 'Access denied. Insufficient permissions.', 403);
    }

    next();
  };
}

module.exports = roleMiddleware;
