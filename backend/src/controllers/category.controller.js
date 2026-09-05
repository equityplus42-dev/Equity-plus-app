const categoryService = require('../services/category.service');
const ApiResponse = require('../utils/apiResponse');

class CategoryController {
  async getAllCategories(req, res, next) {
    try {
      const categories = await categoryService.getAllCategories();
      return ApiResponse.success(res, 'Categories fetched successfully', categories);
    } catch (error) {
      next(error);
    }
  }

  async createCategory(req, res, next) {
    try {
      const { name, description, orderIndex } = req.body;
      const category = await categoryService.createCategory({ name, description, orderIndex });
      return ApiResponse.success(res, 'Category created successfully', category, 201);
    } catch (error) {
      next(error);
    }
  }

  async deleteCategory(req, res, next) {
    try {
      const { id } = req.params;
      const result = await categoryService.deleteCategory(id);
      return ApiResponse.success(res, result.message);
    } catch (error) {
      next(error);
    }
  }
}

module.exports = new CategoryController();
