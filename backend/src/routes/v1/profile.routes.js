const express = require('express');
const router = express.Router();
const profileController = require('../../controllers/profile.controller');
const authMiddleware = require('../../middleware/auth.middleware');
const { uploadSingleImage } = require('../../middleware/upload.middleware');
const validationMiddleware = require('../../middleware/validation.middleware');
const { updateProfileSchema } = require('../../validators/profile.validator');

router.put('/', authMiddleware, validationMiddleware(updateProfileSchema), profileController.updateProfile);
router.post('/avatar', authMiddleware, uploadSingleImage('avatar'), profileController.uploadAvatar);

module.exports = router;
