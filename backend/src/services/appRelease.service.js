const crypto = require('crypto');
const path = require('path');
const fs = require('fs');
const appReleaseRepository = require('../repositories/appRelease.repository');
const cloudflareR2Service = require('./cloudflareR2.service');
const firebaseService = require('./firebase.service');
const { isVersionObsolete, isUpdateAvailable, compareVersions } = require('../utils/semver');
const logger = require('../utils/logger');
const env = require('../config/env');

class AppReleaseService {
  /**
   * Check app version compatibility and return update availability metadata.
   */
  async checkVersion({ appType = 'USER_APP', platform = 'ANDROID', currentVersion = '1.0.0', currentBuildNumber = 1 }) {
    const normalizedAppType = appType.toUpperCase();
    const normalizedPlatform = platform.toUpperCase();
    const parsedBuildNumber = parseInt(currentBuildNumber, 10) || 0;

    const latestRelease = await appReleaseRepository.findLatest({
      appType: normalizedAppType,
      platform: normalizedPlatform,
    });

    if (!latestRelease) {
      return {
        updateAvailable: false,
        forceUpdate: false,
        latestVersion: currentVersion,
        latestBuildNumber: parsedBuildNumber,
        minimumSupportedVersion: null,
        minimumSupportedBuildNumber: null,
        releaseTitle: null,
        releaseNotes: null,
        downloadUrl: null,
        fileSizeBytes: null,
        sha256Checksum: null,
        packageName: null,
      };
    }

    const minVersion = latestRelease.minimumSupportedVersion || latestRelease.version;
    const minBuild = latestRelease.minimumSupportedBuildNumber ?? latestRelease.buildNumber;

    const obsolete = isVersionObsolete({
      currentVersion,
      currentBuildNumber: parsedBuildNumber,
      minimumSupportedVersion: minVersion,
      minimumSupportedBuildNumber: minBuild,
    });

    const updateAvail = isUpdateAvailable({
      currentVersion,
      currentBuildNumber: parsedBuildNumber,
      latestVersion: latestRelease.version,
      latestBuildNumber: latestRelease.buildNumber,
    });

    // Force update if obsolete OR if the latest release explicitly sets forceUpdate=true
    const mustForceUpdate = obsolete || (latestRelease.forceUpdate && updateAvail);

    // Generate active Cloudflare R2 download URL if r2ObjectKey exists or can be extracted
    let activeDownloadUrl = latestRelease.downloadUrl;
    let targetR2Key = latestRelease.r2ObjectKey;

    if (!targetR2Key && latestRelease.downloadUrl) {
      targetR2Key = cloudflareR2Service.extractR2ObjectKeyFromUrl(latestRelease.downloadUrl);
      if (targetR2Key) {
        // Auto-heal database record by storing extracted r2ObjectKey
        try {
          await appReleaseRepository.update(latestRelease.id, { r2ObjectKey: targetR2Key });
        } catch (err) {
          logger.warn(`[AppReleaseService] Non-fatal error auto-healing r2ObjectKey: ${err.message}`);
        }
      }
    }

    if (targetR2Key && cloudflareR2Service.isConfigured()) {
      const isCustomPublicDomain = cloudflareR2Service.publicDomain && !cloudflareR2Service.publicDomain.includes('cloudflarestorage.com');
      if (isCustomPublicDomain) {
        const domain = cloudflareR2Service.publicDomain.replace(/\/$/, '');
        activeDownloadUrl = `${domain}/${targetR2Key}`;
      } else {
        // Generate fresh temporary 1-hour presigned GET URL for direct R2 download (bypasses Vercel/Node bandwidth limits)
        const freshR2Url = await cloudflareR2Service.generatePlaybackUrl(targetR2Key, 3600);
        if (freshR2Url) {
          activeDownloadUrl = freshR2Url;
        } else {
          // Streaming backend fallback if R2 signed URL generation fails
          const domain = process.env.APP_DOMAIN || 'localhost:5000';
          const protocol = process.env.NODE_ENV === 'production' ? 'https' : 'http';
          const apkName = latestRelease.apkFileName || `${normalizedAppType.toLowerCase()}-${latestRelease.version}.apk`;
          activeDownloadUrl = `${protocol}://${domain}/api/v1/app-version/download-file/${normalizedAppType.toLowerCase()}/${latestRelease.version}/${apkName}`;
        }
      }
    }

    return {
      updateAvailable: updateAvail || obsolete,
      forceUpdate: mustForceUpdate,
      latestVersion: latestRelease.version,
      latestBuildNumber: latestRelease.buildNumber,
      minimumSupportedVersion: latestRelease.minimumSupportedVersion,
      minimumSupportedBuildNumber: latestRelease.minimumSupportedBuildNumber,
      releaseTitle: latestRelease.releaseTitle || 'New Update Available',
      releaseNotes: latestRelease.releaseNotes || '',
      downloadUrl: activeDownloadUrl,
      websiteUrl: latestRelease.websiteUrl || process.env.APP_DOWNLOAD_WEBSITE_URL || activeDownloadUrl,
      fileSizeBytes: latestRelease.fileSizeBytes ? Number(latestRelease.fileSizeBytes) : null,
      sha256Checksum: latestRelease.sha256Checksum,
      packageName: latestRelease.packageName,
      releaseId: latestRelease.id,
    };
  }


  /**
   * Admin / Developer: Create a new release with Cloudflare R2 upload & previous APK auto-cleanup.
   */
  async createRelease(adminId, payload, fileBuffer = null) {
    const {
      appType = 'USER_APP',
      platform = 'ANDROID',
      version,
      buildNumber,
      minimumSupportedVersion,
      minimumSupportedBuildNumber,
      forceUpdate = false,
      releaseTitle,
      releaseNotes,
      downloadUrl: providedDownloadUrl,
      apkFileName: providedApkFileName,
      packageName: providedPackageName,
      sha256Checksum: providedChecksum,
    } = payload;

    if (!version || typeof version !== 'string') {
      throw new Error('Valid semver version string is required (e.g. "1.2.0")');
    }

    const parsedBuildNumber = parseInt(buildNumber, 10);
    if (isNaN(parsedBuildNumber)) {
      throw new Error('Valid integer buildNumber is required');
    }

    const normalizedAppType = appType.toUpperCase();
    const normalizedPlatform = platform.toUpperCase();

    // 1. AUTO-CLEANUP: Find and delete all previous APKs for this (appType, platform) from Cloudflare R2 bucket
    const prisma = require('../config/database');
    const existingReleases = await prisma.appRelease.findMany({
      where: {
        appType: normalizedAppType,
        platform: normalizedPlatform,
      },
    });

    for (const oldRelease of existingReleases) {
      const keyOrUrlToDelete = oldRelease.r2ObjectKey || oldRelease.downloadUrl;
      if (keyOrUrlToDelete && cloudflareR2Service.isConfigured()) {
        try {
          await cloudflareR2Service.deleteFile(keyOrUrlToDelete);
          logger.info(`[AppReleaseService] Cleaned up previous Cloudflare R2 APK file: ${keyOrUrlToDelete}`);
        } catch (cleanupErr) {
          logger.warn(`[AppReleaseService] Non-fatal R2 cleanup warning: ${cleanupErr.message}`);
        }
      }

      // Cleanup local fallback file if exists
      if (oldRelease.apkFileName && oldRelease.version) {
        const localPath = path.join(__dirname, '../../uploads/releases', normalizedAppType.toLowerCase(), oldRelease.version, oldRelease.apkFileName);
        if (fs.existsSync(localPath)) {
          try { fs.unlinkSync(localPath); } catch (_) {}
        }
      }
    }

    // Delete old database records to prevent any release data collision
    if (existingReleases.length > 0) {
      await prisma.appRelease.deleteMany({
        where: {
          appType: normalizedAppType,
          platform: normalizedPlatform,
        },
      });
      logger.info(`[AppReleaseService] Deleted ${existingReleases.length} previous AppRelease record(s) to avoid collisions.`);
    }

    let finalDownloadUrl = providedDownloadUrl || null;
    let finalChecksum = providedChecksum || null;
    let fileSize = null;
    let r2ObjectKey = payload.r2ObjectKey || null;

    if (!r2ObjectKey && providedDownloadUrl) {
      r2ObjectKey = cloudflareR2Service.extractR2ObjectKeyFromUrl(providedDownloadUrl);
    }

    let apkFileName = providedApkFileName || `${normalizedAppType.toLowerCase()}-${version}.apk`;
    const packageName = providedPackageName || (normalizedAppType === 'USER_APP' ? 'com.vridhi.userapp' : 'com.vridhi.adminapp');

    // Handle APK file upload if buffer is provided
    if (fileBuffer && Buffer.isBuffer(fileBuffer) && fileBuffer.length > 0) {
      // Validate APK header (ZIP magic bytes PK)
      if (fileBuffer.length < 4 || fileBuffer[0] !== 0x50 || fileBuffer[1] !== 0x4b) {
        throw new Error('Invalid APK file format: Header does not match valid Android package ZIP format');
      }

      // Calculate SHA-256 Checksum
      finalChecksum = crypto.createHash('sha256').update(fileBuffer).digest('hex');
      fileSize = BigInt(fileBuffer.length);

      // Upload file to Cloudflare R2 Storage (or local storage fallback)
      const folderPath = `apks/${normalizedAppType.toLowerCase()}`;

      if (cloudflareR2Service.isConfigured()) {
        try {
          const uploadResult = await cloudflareR2Service.uploadFile(
            fileBuffer,
            folderPath,
            apkFileName,
            'application/vnd.android.package-archive'
          );
          r2ObjectKey = uploadResult.r2ObjectKey;

          const isCustomPublicDomain = cloudflareR2Service.publicDomain && !cloudflareR2Service.publicDomain.includes('cloudflarestorage.com');
          if (isCustomPublicDomain) {
            const domain = cloudflareR2Service.publicDomain.replace(/\/$/, '');
            finalDownloadUrl = `${domain}/${r2ObjectKey}`;
          } else {
            const longLivedPresignedUrl = await cloudflareR2Service.generatePlaybackUrl(r2ObjectKey, 604800);
            finalDownloadUrl = longLivedPresignedUrl || uploadResult.url;
          }

          logger.info(`[AppReleaseService] APK uploaded to Cloudflare R2 bucket: key="${r2ObjectKey}", url="${finalDownloadUrl}"`);
        } catch (r2Err) {
          logger.warn('Failed to upload APK to Cloudflare R2, falling back to local storage', r2Err);
        }
      }

      // Local storage fallback if R2 is not configured or failed
      if (!finalDownloadUrl) {
        const uploadsDir = path.join(__dirname, '../../uploads/releases', normalizedAppType.toLowerCase(), version);
        fs.mkdirSync(uploadsDir, { recursive: true });
        const filePath = path.join(uploadsDir, apkFileName);
        fs.writeFileSync(filePath, fileBuffer);

        const domain = process.env.APP_DOMAIN || 'localhost:5000';
        const protocol = process.env.NODE_ENV === 'production' ? 'https' : 'http';
        finalDownloadUrl = `${protocol}://${domain}/api/v1/app-version/download-file/${normalizedAppType.toLowerCase()}/${version}/${apkFileName}`;
      }
    }

    if (!finalDownloadUrl) {
      throw new Error('Either an APK file must be uploaded or a valid downloadUrl must be provided');
    }

    const releaseData = {
      appType: normalizedAppType,
      platform: normalizedPlatform,
      version,
      buildNumber: parsedBuildNumber,
      minimumSupportedVersion: minimumSupportedVersion || version,
      minimumSupportedBuildNumber: minimumSupportedBuildNumber !== undefined && minimumSupportedBuildNumber !== null
        ? parseInt(minimumSupportedBuildNumber, 10)
        : parsedBuildNumber,
      forceUpdate: forceUpdate === true || forceUpdate === 'true',
      releaseTitle: releaseTitle || `Release ${version}`,
      releaseNotes: releaseNotes || '',
      downloadUrl: finalDownloadUrl,
      websiteUrl: payload.websiteUrl || process.env.APP_DOWNLOAD_WEBSITE_URL || finalDownloadUrl,
      apkFileName,
      r2ObjectKey,
      packageName,

      fileSizeBytes: fileSize,
      sha256Checksum: finalChecksum,
      isActive: true, // Auto-activate newly uploaded release
      isLatest: true,
    };

    const created = await appReleaseRepository.create(releaseData);
    logger.info(`AppRelease created by Developer/Admin ID ${adminId}: ${created.id} (${normalizedAppType} v${version})`);
    return {
      ...created,
      fileSizeBytes: created.fileSizeBytes ? Number(created.fileSizeBytes) : null,
    };
  }

  /**
   * Admin: Activate a release as the latest version and optionally trigger push notifications.
   */
  async activateRelease(adminId, releaseId) {
    const release = await appReleaseRepository.findById(releaseId);
    if (!release) {
      throw new Error('Release record not found');
    }

    const activated = await appReleaseRepository.activateRelease(releaseId, {
      appType: release.appType,
      platform: release.platform,
    });

    logger.info(`AppRelease activated by Admin ID ${adminId}: ${activated.id} (${activated.appType} v${activated.version})`);

    // Dispatch FCM notification asynchronously
    try {
      const title = `🚀 New ${activated.appType === 'USER_APP' ? 'VRIDHI' : 'Admin'} Update Available!`;
      const body = `Version ${activated.version} is now ready. Tap to update your app.`;

      await firebaseService.sendPushNotification('ALL', {
        title,
        body,
        data: {
          type: 'APP_UPDATE',
          appType: activated.appType,
          version: activated.version,
          forceUpdate: String(activated.forceUpdate),
        },
      });
    } catch (pushErr) {
      logger.error('Push notification delivery failed on release activation', pushErr);
      // Non-blocking error
    }

    return activated;
  }

  /**
   * Admin: Deactivate a release
   */
  async deactivateRelease(adminId, releaseId) {
    const release = await appReleaseRepository.findById(releaseId);
    if (!release) {
      throw new Error('Release record not found');
    }

    const deactivated = await appReleaseRepository.deactivateRelease(releaseId);
    logger.info(`AppRelease deactivated by Admin ID ${adminId}: ${releaseId}`);
    return deactivated;
  }

  /**
   * Admin: Delete a release
   */
  async deleteRelease(adminId, releaseId) {
    const release = await appReleaseRepository.findById(releaseId);
    if (!release) {
      throw new Error('Release record not found');
    }

    const keyOrUrlToDelete = release.r2ObjectKey || release.downloadUrl;
    if (keyOrUrlToDelete && cloudflareR2Service.isConfigured()) {
      try {
        await cloudflareR2Service.deleteFile(keyOrUrlToDelete);
        logger.info(`[AppReleaseService] Cleaned up Cloudflare R2 file on release delete: ${keyOrUrlToDelete}`);
      } catch (err) {
        logger.warn(`[AppReleaseService] R2 delete warning: ${err.message}`);
      }
    }

    if (release.apkFileName && release.version) {
      const localPath = path.join(__dirname, '../../uploads/releases', release.appType.toLowerCase(), release.version, release.apkFileName);
      if (fs.existsSync(localPath)) {
        try { fs.unlinkSync(localPath); } catch (_) {}
      }
    }

    const deleted = await appReleaseRepository.deleteRelease(releaseId);
    logger.info(`AppRelease deleted by Admin ID ${adminId}: ${releaseId}`);
    return deleted;
  }

  /**
   * Admin: Rollback to a specific historical release
   */
  async rollbackRelease(adminId, releaseId) {
    return this.activateRelease(adminId, releaseId);
  }

  /**
   * Admin: Fetch all releases
   */
  async getAllReleases({ appType, platform, page = 1, limit = 50 }) {
    const p = Math.max(1, parseInt(page, 10) || 1);
    const l = Math.max(1, parseInt(limit, 10) || 50);
    const offset = (p - 1) * l;

    const { total, releases } = await appReleaseRepository.findAllReleases({
      appType,
      platform,
      limit: l,
      offset,
    });

    const formattedReleases = releases.map((r) => ({
      ...r,
      fileSizeBytes: r.fileSizeBytes ? Number(r.fileSizeBytes) : null,
    }));

    return {
      total,
      page: p,
      limit: l,
      totalPages: Math.ceil(total / l),
      releases: formattedReleases,
    };
  }

  async getReleaseById(releaseId) {
    const release = await appReleaseRepository.findById(releaseId);
    if (!release) return null;
    return {
      ...release,
      fileSizeBytes: release.fileSizeBytes ? Number(release.fileSizeBytes) : null,
    };
  }
}

module.exports = new AppReleaseService();
