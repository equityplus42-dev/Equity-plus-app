const env = require('../config/env');
const path = require('path');
const { randomUUID: uuidv4 } = require('crypto');
const { S3Client, GetObjectCommand, DeleteObjectCommand } = require('@aws-sdk/client-s3');
const { Upload } = require('@aws-sdk/lib-storage');
const { getSignedUrl } = require('@aws-sdk/s3-request-presigner');

class CloudflareR2Service {
  get accountId() { return env.CLOUDFLARE_R2_ACCOUNT_ID || process.env.CLOUDFLARE_R2_ACCOUNT_ID; }
  get accessKeyId() { return env.CLOUDFLARE_R2_ACCESS_KEY_ID || process.env.CLOUDFLARE_R2_ACCESS_KEY_ID; }
  get secretAccessKey() { return env.CLOUDFLARE_R2_SECRET_ACCESS_KEY || process.env.CLOUDFLARE_R2_SECRET_ACCESS_KEY; }
  get bucketName() { return env.CLOUDFLARE_R2_BUCKET_NAME || process.env.CLOUDFLARE_R2_BUCKET_NAME; }
  get publicDomain() { return env.CLOUDFLARE_R2_PUBLIC_DOMAIN || process.env.CLOUDFLARE_R2_PUBLIC_DOMAIN; }

  isConfigured() {
    return Boolean(
      this.accountId &&
      this.accessKeyId &&
      this.secretAccessKey &&
      this.bucketName
    );
  }

  getS3Client() {
    if (!this.isConfigured()) return null;
    return new S3Client({
      region: 'auto',
      endpoint: `https://${this.accountId}.r2.cloudflarestorage.com`,
      forcePathStyle: true,
      credentials: {
        accessKeyId: this.accessKeyId,
        secretAccessKey: this.secretAccessKey,
      },
    });
  }

  /**
   * Extract permanent R2 object key from any R2 URL (presigned or direct).
   *
   * Supports:
   *   https://<account>.r2.cloudflarestorage.com/<bucket>/videos/<uuid>.mp4?X-Amz-...
   *   https://<account>.r2.cloudflarestorage.com/<bucket>/videos/<uuid>.mp4
   *   https://<custom>.r2.dev/videos/<uuid>.mp4
   *
   * Returns: "videos/<uuid>.mp4"  (no query string, no bucket, no protocol/host)
   * Returns: null if URL is not a recognizable R2 URL.
   */
  extractR2ObjectKeyFromUrl(url) {
    if (!url || typeof url !== 'string') return null;

    try {
      const urlObj = new URL(url);
      const hostname = urlObj.hostname;
      const pathname = urlObj.pathname; // Does NOT include query string

      // Case 1: path-style R2 endpoint — https://<account>.r2.cloudflarestorage.com/<bucket>/<key>
      if (hostname.endsWith('.r2.cloudflarestorage.com')) {
        const parts = pathname.split('/').filter(Boolean);
        // parts[0] = bucket name, parts[1..] = object key segments
        if (parts.length >= 2) {
          return parts.slice(1).join('/'); // e.g. "videos/abc.mp4"
        }
        return null;
      }

      // Case 2: R2 custom public domain — https://<pub>.<custom>.r2.dev/<key>
      if (hostname.endsWith('.r2.dev')) {
        const parts = pathname.split('/').filter(Boolean);
        if (parts.length >= 1) {
          return parts.join('/');
        }
        return null;
      }

      return null;
    } catch {
      return null;
    }
  }

  /**
   * Generate a fresh short-lived presigned GET URL for a permanent R2 object key.
   *
   * @param {string} objectKey  — Permanent key, e.g. "videos/<uuid>.mp4"
   * @param {number} expiresInSeconds — Default: 3600 (1 hour). Short TTL is intentional.
   *                                    This is NOT user access lifetime — fresh URLs are
   *                                    generated on every authorized playback request.
   * @returns {string|null} Signed URL valid for expiresInSeconds, or null on failure.
   */
  async generatePlaybackUrl(objectKey, expiresInSeconds = 3600) {
    if (!objectKey) return null;
    if (!this.isConfigured()) {
      console.warn('[CloudflareR2Service] R2 not configured — cannot generate playback URL.');
      return null;
    }
    try {
      const s3Client = this.getS3Client();
      const command = new GetObjectCommand({
        Bucket: this.bucketName,
        Key: objectKey,
      });
      const url = await getSignedUrl(s3Client, command, { expiresIn: expiresInSeconds });
      console.info(`[CloudflareR2Service] Generated ${expiresInSeconds}s playback URL for key: ${objectKey}`);
      return url;
    } catch (error) {
      console.error('[CloudflareR2Service] generatePlaybackUrl failed:', error.message);
      return null;
    }
  }

  /**
   * @deprecated Use generatePlaybackUrl(key, expiresInSeconds) instead.
   * Kept for backward compatibility — same implementation.
   */
  async getPresignedUrl(key, expiresInSeconds = 3600) {
    return this.generatePlaybackUrl(key, expiresInSeconds);
  }

  /**
   * Delete object from Cloudflare R2 bucket by permanent object key OR full URL.
   * Prefers a permanent key. If a URL is given, extracts the key first.
   */
  async deleteFile(keyOrUrl) {
    if (!this.isConfigured() || !keyOrUrl) return false;
    try {
      let key = keyOrUrl;

      // If it looks like a URL, extract the permanent object key
      if (keyOrUrl.startsWith('http://') || keyOrUrl.startsWith('https://')) {
        const extracted = this.extractR2ObjectKeyFromUrl(keyOrUrl);
        if (extracted) {
          key = extracted;
        } else {
          // Fallback: old path-stripping logic for edge cases
          const urlObj = new URL(keyOrUrl);
          const parts = urlObj.pathname.split('/').filter(Boolean);
          if (parts.length >= 2 && parts[0] === this.bucketName) {
            key = parts.slice(1).join('/');
          } else if (parts.length >= 1) {
            key = parts.join('/');
          }
        }
      }

      const s3Client = this.getS3Client();
      const command = new DeleteObjectCommand({
        Bucket: this.bucketName,
        Key: key,
      });

      await s3Client.send(command);
      console.info(`[CloudflareR2Service] Deleted object from R2 bucket "${this.bucketName}": ${key}`);
      return true;
    } catch (error) {
      console.error('[CloudflareR2Service] deleteFile failed:', error.message);
      return false;
    }
  }

  /**
   * High-speed parallel multi-part upload to Cloudflare R2 bucket.
   * Returns { r2ObjectKey, url } where:
   *   - r2ObjectKey is the PERMANENT identifier (store this in Video.r2ObjectKey)
   *   - url is a short-lived 1-hour presigned URL for immediate admin preview
   */
  async uploadFile(fileBuffer, folder = 'videos', originalFilename = 'file.mp4', mimeType = 'video/mp4') {
    const ext = path.extname(originalFilename) || (mimeType.startsWith('video') ? '.mp4' : '.jpg');
    const key = `${folder}/${uuidv4()}${ext}`;

    if (!this.isConfigured()) {
      console.warn('[CloudflareR2Service] R2 not fully configured. Using fallback URL.');
      const domain = this.publicDomain ? this.publicDomain.replace(/\/$/, '') : 'https://pub-r2.dev';
      return { r2ObjectKey: key, url: `${domain}/${key}` };
    }

    try {
      const s3Client = this.getS3Client();
      const parallelUploads3 = new Upload({
        client: s3Client,
        params: {
          Bucket: this.bucketName,
          Key: key,
          Body: fileBuffer,
          ContentType: mimeType,
        },
        queueSize: 4,           // 4 parallel concurrent part uploads
        partSize: 5 * 1024 * 1024, // 5MB part size
        leavePartsOnError: false,
      });

      parallelUploads3.on('httpUploadProgress', (progress) => {
        if (progress.total) {
          const pct = Math.round((progress.loaded / progress.total) * 100);
          console.info(`[CloudflareR2Service] R2 Upload: ${pct}% (${(progress.loaded / 1024 / 1024).toFixed(1)}MB / ${(progress.total / 1024 / 1024).toFixed(1)}MB)`);
        }
      });

      await parallelUploads3.done();

      // Generate a short-lived 1-hour presigned URL for immediate admin preview.
      // This URL is NOT stored as the permanent storage identity.
      // The permanent identity is r2ObjectKey = key.
      const presignedUrl = await this.generatePlaybackUrl(key, 3600);
      const domain = this.publicDomain
        ? this.publicDomain.replace(/\/$/, '')
        : `https://${this.accountId}.r2.cloudflarestorage.com/${this.bucketName}`;
      const previewUrl = presignedUrl || `${domain}/${key}`;

      console.info(`[CloudflareR2Service] Upload complete. r2ObjectKey="${key}"`);
      return { r2ObjectKey: key, url: previewUrl };
    } catch (error) {
      console.error('[CloudflareR2Service] uploadFile failed:', error.message);
      throw error;
    }
  }
}

module.exports = new CloudflareR2Service();
