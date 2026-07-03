const settingsRepository = require('../repositories/settings.repository');
const ApiResponse = require('../utils/apiResponse');

class SettingsController {
  async getSettings(req, res, next) {
    try {
      const records = await settingsRepository.getSettings();
      // Map array to clean key-value object
      const settingsObj = {};
      records.forEach((r) => {
        settingsObj[r.key] = r.value;
      });
      return ApiResponse.success(res, 'System settings retrieved', settingsObj);
    } catch (error) {
      next(error);
    }
  }
}

module.exports = new SettingsController();
