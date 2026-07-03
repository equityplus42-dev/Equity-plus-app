const bcrypt = require('bcrypt');

/**
 * Hash a password string
 * @param {string} password 
 * @returns {Promise<string>}
 */
async function hashPassword(password) {
  const salt = await bcrypt.genSalt(10);
  return bcrypt.hash(password, salt);
}

/**
 * Compare plain text password with its hash
 * @param {string} password 
 * @param {string} hash 
 * @returns {Promise<boolean>}
 */
async function comparePassword(password, hash) {
  return bcrypt.compare(password, hash);
}

module.exports = {
  hashPassword,
  comparePassword,
};
