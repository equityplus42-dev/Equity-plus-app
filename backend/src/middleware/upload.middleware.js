const upload = require('../config/multer');
const { mediaUpload } = require('../config/multer');
const ApiResponse = require('../utils/apiResponse');

const uploadSingleImage = (fieldName) => {
  return (req, res, next) => {
    upload.single(fieldName)(req, res, (err) => {
      if (err) {
        if (err.code === 'LIMIT_FILE_SIZE') {
          return ApiResponse.error(res, 'File size exceeds maximum image limit of 5MB', 413, 'LIMIT_FILE_SIZE');
        }
        return ApiResponse.error(res, err.message, 400);
      }
      next();
    });
  };
};

const uploadSingleMedia = (fieldName) => {
  return (req, res, next) => {
    mediaUpload.single(fieldName)(req, res, (err) => {
      if (err) {
        if (err.code === 'LIMIT_FILE_SIZE') {
          return ApiResponse.error(res, 'File size exceeds the 100MB maximum allowed for video uploads (Cloudinary account plan limit). Please compress your video and try again.', 413, 'LIMIT_FILE_SIZE');
        }
        return ApiResponse.error(res, err.message, 400);
      }
      next();
    });
  };
};

module.exports = {
  uploadSingleImage,
  uploadSingleMedia,
};
