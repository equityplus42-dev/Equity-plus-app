const express = require('express');
const router = express.Router();
const uploadPipelineController = require('../../controllers/uploadPipeline.controller');
const authMiddleware = require('../../middleware/auth.middleware');
const roleMiddleware = require('../../middleware/role.middleware');
const { uploadSingleMedia } = require('../../middleware/upload.middleware');

router.post('/admin', authMiddleware, roleMiddleware(['ADMIN']), uploadPipelineController.processUploadPipeline);
router.post('/media', authMiddleware, roleMiddleware(['ADMIN']), uploadSingleMedia('file'), uploadPipelineController.uploadMedia);

module.exports = router;
