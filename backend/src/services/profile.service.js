const profileRepository = require('../repositories/profile.repository');
const cloudinaryService = require('./cloudinary.service');

class ProfileService {
  async updateProfile(userId, updateData) {
    return profileRepository.update(userId, updateData);
  }

  async updateAvatar(userId, fileBuffer) {
    const avatarUrl = await cloudinaryService.uploadImage(fileBuffer, 'avatars');
    return profileRepository.update(userId, { avatarUrl });
  }
}

module.exports = new ProfileService();
