const express = require('express');
const router = express.Router();
const uploadPipelineController = require('../../controllers/uploadPipeline.controller');
const authMiddleware = require('../../middleware/auth.middleware');
const roleMiddleware = require('../../middleware/role.middleware');

router.post('/admin', authMiddleware, roleMiddleware(['ADMIN']), uploadPipelineController.processUploadPipeline);

module.exports = router;
