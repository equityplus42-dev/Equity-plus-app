const env = require('../config/env');
const path = require('path');
const { v4: uuidv4 } = require('uuid');
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
   * Generate 7-day presigned playback GET URL for Cloudflare R2 object key
   */
  async getPresignedUrl(key, expiresInSeconds = 7 * 24 * 60 * 60) {
    if (!this.isConfigured()) return null;
    try {
      const s3Client = this.getS3Client();
      const command = new GetObjectCommand({
        Bucket: this.bucketName,
        Key: key,
      });
      return await getSignedUrl(s3Client, command, { expiresIn: expiresInSeconds });
    } catch (error) {
      console.error('[CloudflareR2Service] Presigned URL generation failed:', error);
      return null;
    }
  }

  /**
   * Delete object from Cloudflare R2 bucket by key or full URL
   */
  async deleteFile(keyOrUrl) {
    if (!this.isConfigured() || !keyOrUrl) return false;
    try {
      let key = keyOrUrl;
      if (keyOrUrl.startsWith('http://') || keyOrUrl.startsWith('https://')) {
        const urlObj = new URL(keyOrUrl);
        const parts = urlObj.pathname.split('/').filter(Boolean);
        if (parts.length >= 2 && parts[0] === this.bucketName) {
          key = parts.slice(1).join('/');
        } else if (parts.length >= 1) {
          key = parts.join('/');
        }
      }

      const s3Client = this.getS3Client();
      const command = new DeleteObjectCommand({
        Bucket: this.bucketName,
        Key: key,
      });

      await s3Client.send(command);
      console.info(`[CloudflareR2Service] Deleted asset from R2 bucket "${this.bucketName}": ${key}`);
      return true;
    } catch (error) {
      console.error('[CloudflareR2Service] Delete file failed:', error);
      return false;
    }
  }

  /**
   * High-speed parallel multi-part upload to Cloudflare R2 bucket.
   * Returns final public playback / asset URL.
   */
  async uploadFile(fileBuffer, folder = 'videos', originalFilename = 'file.mp4', mimeType = 'video/mp4') {
    const ext = path.extname(originalFilename) || (mimeType.startsWith('video') ? '.mp4' : '.jpg');
    const key = `${folder}/${uuidv4()}${ext}`;

    if (!this.isConfigured()) {
      console.warn('[CloudflareR2Service] R2 environment variables not fully configured. Using fallback URL.');
      const domain = this.publicDomain ? this.publicDomain.replace(/\/$/, '') : 'https://pub-r2.dev';
      return `${domain}/${key}`;
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
        queueSize: 4, // 4 parallel concurrent part uploads
        partSize: 5 * 1024 * 1024, // 5MB part size
        leavePartsOnError: false,
      });

      parallelUploads3.on('httpUploadProgress', (progress) => {
        if (progress.total) {
          const pct = Math.round((progress.loaded / progress.total) * 100);
          console.info(`[CloudflareR2Service] R2 Upload progress: ${pct}% (${(progress.loaded / 1024 / 1024).toFixed(1)}MB / ${(progress.total / 1024 / 1024).toFixed(1)}MB)`);
        }
      });

      await parallelUploads3.done();

      // Generate presigned GET URL for instant 7-day mobile video playback
      const presignedUrl = await this.getPresignedUrl(key);
      const domain = this.publicDomain ? this.publicDomain.replace(/\/$/, '') : `https://${this.accountId}.r2.cloudflarestorage.com/${this.bucketName}`;
      const publicUrl = presignedUrl || `${domain}/${key}`;

      console.info(`[CloudflareR2Service] High-speed upload complete to R2 bucket "${this.bucketName}": ${publicUrl}`);
      return publicUrl;
    } catch (error) {
      console.error('[CloudflareR2Service] Upload failed:', error);
      throw error;
    }
  }
}

module.exports = new CloudflareR2Service();
