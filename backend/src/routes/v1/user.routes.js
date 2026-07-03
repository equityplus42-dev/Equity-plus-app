const express = require('express');
const router = express.Router();
const userController = require('../../controllers/user.controller');
const authMiddleware = require('../../middleware/auth.middleware');
const adminMiddleware = require('../../middleware/admin.middleware');

router.get('/profile', authMiddleware, userController.getProfile);
router.get('/:id', authMiddleware, adminMiddleware, userController.getUserById);
router.get('/', authMiddleware, adminMiddleware, userController.getAllUsers);
router.delete('/:id', authMiddleware, adminMiddleware, userController.deleteUser);

module.exports = router;
