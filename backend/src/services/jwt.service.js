const jwt = require('jsonwebtoken');
const jwtConfig = require('../config/jwt');

class JwtService {
  sign(payload) {
    return jwt.sign(payload, jwtConfig.secret, {
      expiresIn: jwtConfig.expiresIn,
    });
  }

  verify(token) {
    return jwt.verify(token, jwtConfig.secret);
  }
}

module.exports = new JwtService();
