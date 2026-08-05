const express = require('express');
const router = express.Router();
const languageController = require('../../controllers/language.controller');
const authMiddleware = require('../../middleware/auth.middleware');
const roleMiddleware = require('../../middleware/role.middleware');

// Public / Authenticated route to get all languages
router.get('/', authMiddleware, languageController.getAllLanguages);

// Admin only routes
router.post('/', authMiddleware, roleMiddleware(['ADMIN']), languageController.createLanguage);
router.delete('/:id', authMiddleware, roleMiddleware(['ADMIN']), languageController.deleteLanguage);

module.exports = router;
