/**
 * Calculate pagination offsets
 * @param {number|string} page 
 * @param {number|string} limit 
 * @returns {{skip: number, take: number, page: number, limit: number}}
 */
function getPaginationParams(page = 1, limit = 10) {
  const parsedPage = Math.max(1, parseInt(page) || 1);
  const parsedLimit = Math.max(1, Math.min(100, parseInt(limit) || 10)); // Cap limit at 100
  const skip = (parsedPage - 1) * parsedLimit;
  
  return {
    skip,
    take: parsedLimit,
    page: parsedPage,
    limit: parsedLimit,
  };
}

/**
 * Format paginated results
 * @param {Array} data 
 * @param {number} totalItems 
 * @param {number} page 
 * @param {number} limit 
 * @returns {{items: Array, pagination: {page: number, limit: number, totalItems: number, totalPages: number, hasNext: boolean, hasPrevious: boolean}}}
 */
function formatPaginatedResponse(data, totalItems, page, limit) {
  const totalPages = Math.ceil(totalItems / limit);
  return {
    items: data,
    pagination: {
      page,
      limit,
      totalItems,
      totalPages,
      hasNext: page < totalPages,
      hasPrevious: page > 1,
    },
  };
}

module.exports = {
  getPaginationParams,
  formatPaginatedResponse,
};
