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
    throw new Error('Cloudinary video upload is permanently disabled. All video content must be uploaded directly to Cloudflare R2 Bucket.');
  }
}

module.exports = new CloudinaryService();

