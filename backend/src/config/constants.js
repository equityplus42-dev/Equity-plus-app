module.exports = {
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
    require_admin_approval: true,
  },
};
