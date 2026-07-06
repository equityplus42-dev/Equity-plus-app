const userSearchService = require('../services/userSearch.service');
const adminSearchService = require('../services/adminSearch.service');
const ApiResponse = require('../utils/apiResponse');
const { getPaginationParams, formatPaginatedResponse } = require('../utils/pagination');

class SearchController {
  async searchUsers(req, res, next) {
    try {
      const { query, page, limit } = req.query;
      const { skip, take, page: p, limit: l } = getPaginationParams(page, limit);

      let result;
      if (req.user.role === 'ADMIN') {
        // Global administrative lookup
        result = await adminSearchService.searchGlobal(query, skip, take);
      } else {
        // Search restricted to downline descendants
        result = await userSearchService.searchVisibleHierarchy(req.user.id, query, skip, take);
      }

      const { users, total } = result;

      // Sanitization: omit hashed passwords and mask downline sensitive data for standard users
      let sanitizedUsers;
      if (req.user.role === 'ADMIN') {
        sanitizedUsers = users.map(({ password, ...u }) => u);
      } else {
        sanitizedUsers = users.map(({ password, email, ...u }) => {
          const maskedProfile = u.profile ? {
            firstName: u.referralCode || 'User',
            lastName: '',
            phoneNumber: u.profile.phoneNumber || 'N/A',
            avatarUrl: null,
          } : null;
          return {
            ...u,
            email: u.profile?.phoneNumber || 'N/A',
            profile: maskedProfile,
          };
        });
      }

      const responseData = formatPaginatedResponse(sanitizedUsers, total, p, l);
      return ApiResponse.success(res, 'Search completed successfully', responseData);
    } catch (error) {
      next(error);
    }
  }
}

module.exports = new SearchController();
