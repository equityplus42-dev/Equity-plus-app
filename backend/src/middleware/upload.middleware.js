const upload = require('../config/multer');
const { mediaUpload } = require('../config/multer');
const ApiResponse = require('../utils/apiResponse');

const uploadSingleImage = (fieldName) => {
  return (req, res, next) => {
    upload.single(fieldName)(req, res, (err) => {
      if (err) {
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
