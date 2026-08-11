const { primaryConfig, videoConfig, uploadWithConfig } = require('../config/cloudinary');

class CloudinaryService {
  /**
   * Upload image buffer to PRIMARY Cloudinary (Avatars, Thumbnails, Campaigns)
   * @param {Buffer} buffer
   * @param {string} folder
   * @returns {Promise<string>} - The secure URL
   */
  async uploadImage(buffer, folder = 'avatars') {
    if (!primaryConfig.cloud_name || !primaryConfig.api_key || !primaryConfig.api_secret) {
      console.warn('[CloudinaryService] Primary Cloudinary not configured. Returning mock avatar URL.');
      const mockAvatars = [
        'https://images.unsplash.com/photo-1535713875002-d1d0cf377fde?auto=format&fit=crop&w=150&h=150',
        'https://images.unsplash.com/photo-1494790108377-be9c29b29330?auto=format&fit=crop&w=150&h=150',
        'https://images.unsplash.com/photo-1599566150163-29194dcaad36?auto=format&fit=crop&w=150&h=150',
        'https://images.unsplash.com/photo-1570295999919-56ceb5ecca61?auto=format&fit=crop&w=150&h=150',
      ];
      return mockAvatars[Math.floor(Math.random() * mockAvatars.length)];
    }

    const result = await uploadWithConfig(primaryConfig, buffer, {
      folder,
      resource_type: 'image',
    });
    return result.secure_url;
  }

  /**
   * Upload video buffer STRICTLY to DEDICATED VIDEO Cloudinary account
   * Account: cloud_name = qv1eskbe (from CLOUDINARY_VIDEO_* env vars)
   * NO fallback permitted.
   * @param {Buffer} buffer
   * @param {string} folder
   * @returns {Promise<{url: string, duration: number}>}
   */
  async uploadVideo(buffer, folder = 'videos') {
    const hasVideoConfig = videoConfig.cloud_name && videoConfig.api_key && videoConfig.api_secret;

    if (!hasVideoConfig) {
      throw new Error(
        '[CloudinaryService] Dedicated Video Cloudinary (CLOUDINARY_VIDEO_*) configuration is missing. ' +
        'Video uploads require the dedicated video account (cloud: qv1eskbe). No fallback is permitted.'
      );
    }

    console.info(`[CloudinaryService] Uploading video strictly to Dedicated Video Cloudinary account: ${videoConfig.cloud_name}`);

    const result = await uploadWithConfig(videoConfig, buffer, {
      folder,
      resource_type: 'video',
      // ── Eager Transcoding ─────────────────────────────────────────────────────
      // Pre-process the video into multiple quality renditions immediately on upload
      // so no user ever triggers the first-play encoding lag.
      eager: [
        // HLS Adaptive Bitrate (Auto quality — best for native apps)
        { streaming_profile: 'hd', format: 'm3u8' },
        { streaming_profile: 'sd', format: 'm3u8' },
        // Fixed quality MP4s (for quality selector in app)
        { width: 1920, height: 1080, crop: 'limit', quality: 'auto', format: 'mp4' },
        { width: 1280, height: 720,  crop: 'limit', quality: 'auto', format: 'mp4' },
        { width: 854,  height: 480,  crop: 'limit', quality: 'auto', format: 'mp4' },
        { width: 640,  height: 360,  crop: 'limit', quality: 'auto', format: 'mp4' },
        { width: 426,  height: 240,  crop: 'limit', quality: 'auto', format: 'mp4' },
      ],
      eager_async: true, // Don't block upload response — process renditions in background
    });

    const durationSecs = result.duration ? Math.round(result.duration) : 0;
    return { url: result.secure_url, duration: durationSecs };
  }
}

module.exports = new CloudinaryService();

