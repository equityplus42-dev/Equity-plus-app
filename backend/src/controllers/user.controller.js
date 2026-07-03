const userRepository = require('../repositories/user.repository');
const ApiResponse = require('../utils/apiResponse');
const auditLogService = require('../services/auditLog.service');
const { getPaginationParams, formatPaginatedResponse } = require('../utils/pagination');

class UserController {
  async getProfile(req, res, next) {
    try {
      const user = await userRepository.findById(req.user.id);
      if (!user) {
        return ApiResponse.error(res, 'User not found', 404);
      }
      
      const { password, ...userWithoutPassword } = user;
      return ApiResponse.success(res, 'Profile retrieved', userWithoutPassword);
    } catch (error) {
      next(error);
    }
  }

  async getUserById(req, res, next) {
    try {
      const user = await userRepository.findById(req.params.id);
      if (!user) {
        return ApiResponse.error(res, 'User not found', 404);
      }
      
      const { password, ...userWithoutPassword } = user;
      return ApiResponse.success(res, 'User details retrieved', userWithoutPassword);
    } catch (error) {
      next(error);
    }
  }

  async getAllUsers(req, res, next) {
    try {
      const { page, limit } = req.query;
      const search = req.query.search || '';
      
      const { skip, take, page: p, limit: l } = getPaginationParams(page, limit);
      
      const users = await userRepository.findAll({ skip, take, search });
      const total = await userRepository.countAll({ search });
      
      // Strip passwords
      const sanitizedUsers = users.map(({ password, ...u }) => u);
      
      const responseData = formatPaginatedResponse(sanitizedUsers, total, p, l);
      return ApiResponse.success(res, 'Users retrieved successfully', responseData);
    } catch (error) {
      next(error);
    }
  }

  async deleteUser(req, res, next) {
    try {
      await userRepository.deleteUser(req.params.id);
      await auditLogService.log(req, 'USER_DELETE', req.params.id, { deletedBy: req.user.id });
      return ApiResponse.success(res, 'User deleted successfully');
    } catch (error) {
      next(error);
    }
  }
}

module.exports = new UserController();
