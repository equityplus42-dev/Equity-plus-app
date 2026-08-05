const express = require('express');
const router = express.Router();
const productController = require('../../controllers/product.controller');
const authMiddleware = require('../../middleware/auth.middleware');
const roleMiddleware = require('../../middleware/role.middleware');

// Public / Authenticated routes
router.get('/', authMiddleware, productController.getAllProducts);

// Admin routes
router.post('/admin', authMiddleware, roleMiddleware(['ADMIN']), productController.createProduct);
router.put('/admin/:id', authMiddleware, roleMiddleware(['ADMIN']), productController.updateProduct);
router.patch('/admin/:id/archive', authMiddleware, roleMiddleware(['ADMIN']), productController.archiveProduct);
router.put('/admin/users/:id/product', authMiddleware, roleMiddleware(['ADMIN']), productController.assignUserProduct);

module.exports = router;
