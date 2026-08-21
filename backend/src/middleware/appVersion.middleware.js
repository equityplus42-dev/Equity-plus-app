const appReleaseService = require('../services/appRelease.service');
const ApiResponse = require('../utils/apiResponse');
const logger = require('../utils/logger');

// Explicit paths to bypass version enforcement
const EXCLUDED_PATHS = [
  '/health',
  '/api/health',
  '/api/v1/health',
  '/api/docs',
  '/api/v1/app-version/check',
  '/api/v1/app-version/download-file',
  '/api/v1/auth/login',
  '/api/v1/auth/register',
  '/api/v1/auth/forgot-password',
];

async function appVersionMiddleware(req, res, next) {
  try {
    // 1. Check if version enforcement is globally disabled
    if (process.env.APP_VERSION_ENFORCEMENT_ENABLED === 'false') {
      return next();
    }

    const pathName = req.path || req.originalUrl || '';

    // 2. Check excluded endpoints
    const isExcluded = EXCLUDED_PATHS.some((excluded) => pathName.startsWith(excluded)) ||
      pathName.includes('/app-version/admin') ||
      pathName.includes('/app-version/download');

    if (isExcluded) {
      return next();
    }

    // 3. Extract version headers sent by Flutter mobile apps
    const appType = req.headers['x-app-type'];
    const platform = req.headers['x-app-platform'];
    const currentVersion = req.headers['x-app-version'];
    const currentBuildNumber = req.headers['x-app-build-number'];

    // 4. Pass through safely if headers are not present (web dashboard, Postman, non-mobile clients)
    if (!appType || !currentVersion) {
      return next();
    }

    // 5. Evaluate compatibility against active latest release
    const checkResult = await appReleaseService.checkVersion({
      appType,
      platform: platform || 'ANDROID',
      currentVersion,
      currentBuildNumber: currentBuildNumber || 1,
    });

    // 6. Block request if client version is obsolete / force update required
    if (checkResult.forceUpdate) {
      logger.warn(`Blocked API request from obsolete ${appType} version v${currentVersion} (Build ${currentBuildNumber})`);
      return res.status(426).json({
        success: false,
        errorCode: 'APP_UPDATE_REQUIRED',
        message: 'A newer version of the application is required to continue using the VRIDHI platform.',
        data: {
          forceUpdate: true,
          latestVersion: checkResult.latestVersion,
          latestBuildNumber: checkResult.latestBuildNumber,
          minimumSupportedVersion: checkResult.minimumSupportedVersion,
          minimumSupportedBuildNumber: checkResult.minimumSupportedBuildNumber,
          downloadUrl: checkResult.downloadUrl,
          releaseTitle: checkResult.releaseTitle,
          releaseNotes: checkResult.releaseNotes,
          sha256Checksum: checkResult.sha256Checksum,
          fileSizeBytes: checkResult.fileSizeBytes,
        },
      });
    }

    next();
  } catch (err) {
    logger.error('Error in appVersionMiddleware:', err);
    // Non-blocking fallback on internal errors
    next();
  }
}

module.exports = appVersionMiddleware;
