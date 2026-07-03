const env = require('./env');

module.exports = {
  secret: env.JWT_SECRET,
  expiresIn: env.JWT_EXPIRES_IN,
};
