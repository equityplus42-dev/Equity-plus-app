const { Readable } = require('stream');
const { cloudinary, videoCloudinary } = require('../config/cloudinary');

class CloudinaryService {
  /**
   * Upload image buffer to Cloudinary (Primary Account)
   * @param {Buffer} buffer 
   * @param {string} folder 
   * @returns {Promise<string>} - The secure url
   */
  async uploadImage(buffer, folder = 'avatars') {
    // Check if Cloudinary is configured
    if (!cloudinary.config().cloud_name) {
      console.warn('[CloudinaryService] Primary Cloudinary not configured. Returning default mock placeholder URL.');
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

      const stream = new Readable();
      stream.push(buffer);
      stream.push(null);
      stream.pipe(uploadStream);
    });
  }

  /**
   * Upload video buffer to Video Cloudinary (Dedicated Video Account)
   * @param {Buffer} buffer 
   * @param {string} folder 
   * @returns {Promise<string>} - The secure url
   */
  async uploadVideo(buffer, folder = 'videos') {
    if (!videoCloudinary.config().cloud_name) {
      console.warn('[CloudinaryService] Video Cloudinary not configured. Returning default mock video URL.');
      return 'https://commondatastorage.googleapis.com/gtv-videos-bucket/sample/ForBiggerBlazes.mp4';
    }

    return new Promise((resolve, reject) => {
      const uploadStream = videoCloudinary.uploader.upload_stream(
        { folder: folder, resource_type: 'video' },
        (error, result) => {
          if (error) {
            console.error('[CloudinaryService] Video upload error:', error);
            return reject(new Error('Cloudinary video upload failed'));
          }
          // result.duration is in seconds (float), round to nearest integer
          const durationSecs = result.duration ? Math.round(result.duration) : 0;
          resolve({ url: result.secure_url, duration: durationSecs });
        }
      );

      const stream = new Readable();
      stream.push(buffer);
      stream.push(null);
      stream.pipe(uploadStream);
    });
  }
}

module.exports = new CloudinaryService();
