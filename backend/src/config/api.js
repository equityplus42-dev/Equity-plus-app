/**
 * API Global Configuration Constants
 */
module.exports = {
  VERSION: 'v1',
  
  PAGINATION: {
    DEFAULT_PAGE: 1,
    DEFAULT_LIMIT: 10,
    MAX_LIMIT: 100,
  },
  
  RATE_LIMIT: {
    WINDOW_MS: 15 * 60 * 1000, // 15 minutes
    MAX_REQUESTS: 100,         // Limit each IP to 100 requests per window
  },
  
  RESPONSE: {
    SUCCESS_DEFAULT_MESSAGE: 'Success',
    ERROR_DEFAULT_MESSAGE: 'An error occurred',
  },
  
  ROLES: {
    USER: 'USER',
    ADMIN: 'ADMIN',
  },
  
  REFERRAL_STATUS: {
    PENDING: 'PENDING',
    APPROVED: 'APPROVED',
    REJECTED: 'REJECTED',
  },
  
  SETTINGS_KEYS: {
    POINTS_L1: 'points_level_1',
    POINTS_L2: 'points_level_2',
    POINTS_L3: 'points_level_3',
    MAX_DEPTH: 'max_hierarchy_depth',
    REQUIRE_APPROVAL: 'require_admin_approval',
  },
  
  DEFAULT_SETTINGS: {
    points_level_1: 100,
    points_level_2: 50,
    points_level_3: 25,
    max_hierarchy_depth: 3,
    require_admin_approval: false,
  },
};
