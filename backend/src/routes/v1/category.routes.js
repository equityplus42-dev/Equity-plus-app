const express = require('express');
const router = express.Router();
const categoryController = require('../../controllers/category.controller');
const authMiddleware = require('../../middleware/auth.middleware');
const roleMiddleware = require('../../middleware/role.middleware');

// Public / Authenticated: Get all categories
router.get('/', categoryController.getAllCategories);

// Admin endpoints: Create and Delete categories
router.post('/', authMiddleware, roleMiddleware(['ADMIN', 'DEVELOPER']), categoryController.createCategory);
router.delete('/:id', authMiddleware, roleMiddleware(['ADMIN', 'DEVELOPER']), categoryController.deleteCategory);

module.exports = router;
