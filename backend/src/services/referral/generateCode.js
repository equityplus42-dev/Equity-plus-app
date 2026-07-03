const crypto = require('crypto');

/**
 * Generate a random uppercase alphanumeric string
 * @param {number} length 
 * @returns {string}
 */
function generateCode(length = 8) {
  const chars = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789';
  let result = '';
  const randomBytes = crypto.randomBytes(length);
  for (let i = 0; i < length; i++) {
    result += chars[randomBytes[i] % chars.length];
  }
  return result;
}

module.exports = generateCode;
