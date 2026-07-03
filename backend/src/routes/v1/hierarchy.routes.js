const express = require('express');
const router = express.Router();
const hierarchyController = require('../../controllers/hierarchy.controller');
const authMiddleware = require('../../middleware/auth.middleware');
const adminMiddleware = require('../../middleware/admin.middleware');
const validationMiddleware = require('../../middleware/validation.middleware');
const { getHierarchySchema } = require('../../validators/hierarchy.validator');

router.get('/', authMiddleware, validationMiddleware(getHierarchySchema, 'query'), hierarchyController.getUserHierarchy);
router.get('/global', authMiddleware, adminMiddleware, hierarchyController.getGlobalHierarchy);

module.exports = router;
