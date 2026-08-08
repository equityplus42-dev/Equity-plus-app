const express = require('express');
const router = express.Router();
const languageController = require('../../controllers/language.controller');
const authMiddleware = require('../../middleware/auth.middleware');
const roleMiddleware = require('../../middleware/role.middleware');

// Public route to get all languages for registration & video hub
router.get('/', languageController.getAllLanguages);

// Admin only routes
router.post('/', authMiddleware, roleMiddleware(['ADMIN']), languageController.createLanguage);
router.delete('/:id', authMiddleware, roleMiddleware(['ADMIN']), languageController.deleteLanguage);

module.exports = router;
