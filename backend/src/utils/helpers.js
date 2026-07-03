/**
 * Validate if a string is a valid UUID
 * @param {string} uuid 
 * @returns {boolean}
 */
function isValidUUID(uuid) {
  const regex = /^[0-9a-f]{8}-[0-9a-f]{4}-[1-5][0-9a-f]{3}-[89ab][0-9a-f]{3}-[0-9a-f]{12}$/i;
  return regex.test(uuid);
}

/**
 * Clean up object by removing undefined fields
 * @param {Object} obj 
 * @returns {Object}
 */
function removeUndefinedFields(obj) {
  const result = { ...obj };
  Object.keys(result).forEach(key => result[key] === undefined && delete result[key]);
  return result;
}

module.exports = {
  isValidUUID,
  removeUndefinedFields,
};
