const express = require('express');
const router = express.Router();
const appReleaseController = require('../../controllers/appRelease.controller');
const authMiddleware = require('../../middleware/auth.middleware');
const developerMiddleware = require('../../middleware/developer.middleware');
const { uploadSingleApk } = require('../../middleware/upload.middleware');

// Public route: check latest app version
router.get('/check', (req, res, next) => appReleaseController.checkVersion(req, res, next));

// Public route: direct APK download endpoint for locally hosted releases
router.get('/download-file/:appType/:version/:filename', (req, res, next) => appReleaseController.downloadFile(req, res, next));

// Developer-only release management routes
router.get('/admin/releases', authMiddleware, developerMiddleware, (req, res, next) => appReleaseController.getAllReleases(req, res, next));
router.get('/admin/releases/:id', authMiddleware, developerMiddleware, (req, res, next) => appReleaseController.getReleaseById(req, res, next));
router.post('/admin/releases', authMiddleware, developerMiddleware, uploadSingleApk('apkFile'), (req, res, next) => appReleaseController.createRelease(req, res, next));
router.post('/admin/releases/:id/activate', authMiddleware, developerMiddleware, (req, res, next) => appReleaseController.activateRelease(req, res, next));
router.post('/admin/releases/:id/deactivate', authMiddleware, developerMiddleware, (req, res, next) => appReleaseController.deactivateRelease(req, res, next));
router.delete('/admin/releases/:id', authMiddleware, developerMiddleware, (req, res, next) => appReleaseController.deleteRelease(req, res, next));
router.post('/admin/releases/:id/rollback', authMiddleware, developerMiddleware, (req, res, next) => appReleaseController.rollbackRelease(req, res, next));

module.exports = router;
