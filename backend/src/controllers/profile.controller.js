const profileService = require('../services/profile.service');
const ApiResponse = require('../utils/apiResponse');
const auditLogService = require('../services/auditLog.service');

class ProfileController {
  async updateProfile(req, res, next) {
    try {
      const profile = await profileService.updateProfile(req.user.id, req.body);
      await auditLogService.log(req, 'PROFILE_UPDATE', req.user.id, { fields: Object.keys(req.body) });
      return ApiResponse.success(res, 'Profile updated successfully', profile);
    } catch (error) {
      next(error);
    }
  }

  async uploadAvatar(req, res, next) {
    try {
      if (!req.file) {
        return ApiResponse.error(res, 'No image file uploaded', 400);
      }
      
      const profile = await profileService.updateAvatar(req.user.id, req.file.buffer);
      await auditLogService.log(req, 'AVATAR_UPDATE', req.user.id);
      return ApiResponse.success(res, 'Avatar uploaded successfully', profile);
    } catch (error) {
      next(error);
    }
  }
}

module.exports = new ProfileController();
