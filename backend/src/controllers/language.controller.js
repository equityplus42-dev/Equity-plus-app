const languageService = require('../services/language.service');
const ApiResponse = require('../utils/apiResponse');

class LanguageController {
  async getAllLanguages(req, res, next) {
    try {
      const languages = await languageService.getAllLanguages();
      return ApiResponse.success(res, 'Languages fetched successfully', languages);
    } catch (error) {
      next(error);
    }
  }

  async createLanguage(req, res, next) {
    try {
      const { name, code } = req.body;
      if (!name) {
        return ApiResponse.error(res, 'Language name is required', 400);
      }
      const language = await languageService.createLanguage({ name, code });
      return ApiResponse.success(res, 'Language created successfully', language, 201);
    } catch (error) {
      next(error);
    }
  }

  async deleteLanguage(req, res, next) {
    try {
      const { id } = req.params;
      await languageService.deleteLanguage(id);
      return ApiResponse.success(res, 'Language deleted successfully');
    } catch (error) {
      next(error);
    }
  }
}

module.exports = new LanguageController();
