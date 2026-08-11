const express = require('express');
const router = express.Router();
const uploadPipelineController = require('../../controllers/uploadPipeline.controller');
const authMiddleware = require('../../middleware/auth.middleware');
const roleMiddleware = require('../../middleware/role.middleware');
const { uploadSingleMedia } = require('../../middleware/upload.middleware');

router.post('/admin', authMiddleware, roleMiddleware(['ADMIN']), uploadPipelineController.processUploadPipeline);

// No timeout for video uploads — large 4K files can take minutes to upload
const noTimeout = (req, res, next) => {
  req.socket.setTimeout(0);
  res.setTimeout(0);
  next();
};
router.post('/media', authMiddleware, roleMiddleware(['ADMIN']), noTimeout, uploadSingleMedia('file'), uploadPipelineController.uploadMedia);

module.exports = router;
