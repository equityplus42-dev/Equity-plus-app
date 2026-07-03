const { Readable } = require('stream');
const cloudinary = require('../config/cloudinary');

class CloudinaryService {
  /**
   * Upload image buffer to Cloudinary
   * @param {Buffer} buffer 
   * @param {string} folder 
   * @returns {Promise<string>} - The secure url
   */
  async uploadImage(buffer, folder = 'avatars') {
    // Check if Cloudinary is configured
    if (!cloudinary.config().cloud_name) {
      console.warn('[CloudinaryService] Cloudinary not configured. Returning default mock placeholder URL.');
      // Return a premium looking mock avatar URL
      const mockAvatars = [
        'https://images.unsplash.com/photo-1535713875002-d1d0cf377fde?auto=format&fit=crop&w=150&h=150',
        'https://images.unsplash.com/photo-1494790108377-be9c29b29330?auto=format&fit=crop&w=150&h=150',
        'https://images.unsplash.com/photo-1599566150163-29194dcaad36?auto=format&fit=crop&w=150&h=150',
        'https://images.unsplash.com/photo-1570295999919-56ceb5ecca61?auto=format&fit=crop&w=150&h=150'
      ];
      const randomIndex = Math.floor(Math.random() * mockAvatars.length);
      return mockAvatars[randomIndex];
    }

    return new Promise((resolve, reject) => {
      const uploadStream = cloudinary.uploader.upload_stream(
        { folder: folder },
        (error, result) => {
          if (error) {
            console.error('[CloudinaryService] Upload error:', error);
            return reject(new Error('Cloudinary upload failed'));
          }
          resolve(result.secure_url);
        }
      );

      // Convert buffer to stream and pipe to cloudinary upload stream
      const stream = new Readable();
      stream.push(buffer);
      stream.push(null);
      stream.pipe(uploadStream);
    });
  }
}

module.exports = new CloudinaryService();
