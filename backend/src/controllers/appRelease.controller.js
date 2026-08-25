const path = require('path');
const fs = require('fs');
const appReleaseService = require('../services/appRelease.service');
const ApiResponse = require('../utils/apiResponse');

class AppReleaseController {
  async checkVersion(req, res, next) {
    try {
      const appType = req.query.appType || req.headers['x-app-type'] || 'USER_APP';
      const platform = req.query.platform || req.headers['x-app-platform'] || 'ANDROID';
      const currentVersion = req.query.currentVersion || req.headers['x-app-version'] || '1.0.0';
      const currentBuildNumber = req.query.currentBuildNumber || req.headers['x-app-build-number'] || 1;

      const result = await appReleaseService.checkVersion({
        appType,
        platform,
        currentVersion,
        currentBuildNumber,
      });

      return ApiResponse.success(res, 'App version check completed', result);
    } catch (err) {
      next(err);
    }
  }

  async getAllReleases(req, res, next) {
    try {
      const { appType, platform, page, limit } = req.query;
      const result = await appReleaseService.getAllReleases({ appType, platform, page, limit });
      return ApiResponse.success(res, 'Releases fetched successfully', result);
    } catch (err) {
      next(err);
    }
  }

  async getReleaseById(req, res, next) {
    try {
      const release = await appReleaseService.getReleaseById(req.params.id);
      if (!release) {
        return ApiResponse.error(res, 'Release not found', 404);
      }
      return ApiResponse.success(res, 'Release details fetched successfully', release);
    } catch (err) {
      next(err);
    }
  }

  async createRelease(req, res, next) {
    try {
      const adminId = req.user.id;
      const fileBuffer = req.file ? req.file.buffer : null;
      const payload = req.body;

      if (req.file && req.file.originalname) {
        payload.apkFileName = req.file.originalname;
      }

      const release = await appReleaseService.createRelease(adminId, payload, fileBuffer);
      return ApiResponse.success(res, 'Release created successfully', release, 201);
    } catch (err) {
      next(err);
    }
  }

  async getPresignedUploadUrl(req, res, next) {
    try {
      const cloudflareR2Service = require('../services/cloudflareR2.service');
      const { filename = 'app-release.apk', mimeType = 'application/vnd.android.package-archive' } = req.body;
      const result = await cloudflareR2Service.generateUploadUrl('releases', filename, mimeType);
      return ApiResponse.success(res, 'APK Presigned upload URL generated successfully', result);
    } catch (err) {
      next(err);
    }
  }

  async activateRelease(req, res, next) {
    try {
      const adminId = req.user.id;
      const release = await appReleaseService.activateRelease(adminId, req.params.id);
      return ApiResponse.success(res, 'Release activated successfully', release);
    } catch (err) {
      next(err);
    }
  }

  async deactivateRelease(req, res, next) {
    try {
      const adminId = req.user.id;
      const release = await appReleaseService.deactivateRelease(adminId, req.params.id);
      return ApiResponse.success(res, 'Release deactivated successfully', release);
    } catch (err) {
      next(err);
    }
  }

  async deleteRelease(req, res, next) {
    try {
      const adminId = req.user.id;
      const release = await appReleaseService.deleteRelease(adminId, req.params.id);
      return ApiResponse.success(res, 'Release deleted successfully', release);
    } catch (err) {
      next(err);
    }
  }

  async rollbackRelease(req, res, next) {
    try {
      const adminId = req.user.id;
      const release = await appReleaseService.rollbackRelease(adminId, req.params.id);
      return ApiResponse.success(res, 'Rollback completed successfully', release);
    } catch (err) {
      next(err);
    }
  }

  async downloadFile(req, res, next) {
    try {
      const { appType, version, filename } = req.params;
      const filePath = path.join(__dirname, '../../uploads/releases', appType.toLowerCase(), version, filename);

      if (!fs.existsSync(filePath)) {
        return ApiResponse.error(res, 'Requested APK file was not found on server', 404);
      }

      res.setHeader('Content-Type', 'application/vnd.android.package-archive');
      res.setHeader('Content-Disposition', `attachment; filename="${filename}"`);
      return res.sendFile(filePath);
    } catch (err) {
      next(err);
    }
  }
}

module.exports = new AppReleaseController();
