const jwt = require('jsonwebtoken');
const jwtConfig = require('../config/jwt');
const ApiResponse = require('../utils/apiResponse');

function authMiddleware(req, res, next) {
  const authHeader = req.headers.authorization;
  
  if (!authHeader || !authHeader.startsWith('Bearer ')) {
    return ApiResponse.error(res, 'Access denied. No token provided.', 401);
  }

  const token = authHeader.split(' ')[1];

  try {
    const decoded = jwt.verify(token, jwtConfig.secret);
    req.user = decoded; // Contains id, email, role
    next();
  } catch (error) {
    if (error.name === 'TokenExpiredError') {
      return ApiResponse.error(res, 'Token expired.', 401);
    }
    return ApiResponse.error(res, 'Invalid token.', 401);
  }
}

module.exports = authMiddleware;
