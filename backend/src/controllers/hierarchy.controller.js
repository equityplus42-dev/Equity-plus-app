const hierarchyService = require('../services/hierarchy.service');
const ApiResponse = require('../utils/apiResponse');

class HierarchyController {
  async getUserHierarchy(req, res, next) {
    try {
      const isAdmin = req.user.role === 'ADMIN';
      let depth = req.query.depth ? parseInt(req.query.depth, 10) : undefined;
      
      if (!isAdmin) {
        // For standard users, restrict depth to a maximum of 4 levels of referees
        depth = depth !== undefined ? Math.min(depth, 4) : 4;
      }

      const tree = await hierarchyService.getUserHierarchy(req.user.id, depth);
      return ApiResponse.success(res, 'User referral hierarchy retrieved', tree);
    } catch (error) {
      next(error);
    }
  }

  async getGlobalHierarchy(req, res, next) {
    try {
      const tree = await hierarchyService.getGlobalHierarchy();
      return ApiResponse.success(res, 'Global referral hierarchy tree retrieved', tree);
    } catch (error) {
      next(error);
    }
  }
}

module.exports = new HierarchyController();
