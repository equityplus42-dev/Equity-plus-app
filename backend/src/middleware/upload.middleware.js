const upload = require('../config/multer');
const { mediaUpload, apkUpload } = require('../config/multer');
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
    // Vercel Serverless Functions enforce a hard 4.5MB request body limit.
    // If request exceeds 4MB, inform user to use direct presigned URLs.
    const contentLength = parseInt(req.headers['content-length'] || '0', 10);
    if (contentLength > 4 * 1024 * 1024) {
      return ApiResponse.error(
        res,
        'Direct file upload to Vercel endpoint exceeds Vercel serverless 4.5MB payload limit. For files larger than 4MB (like 30-40MB videos), please use direct presigned uploads (/upload-pipeline/presigned-url or /upload-pipeline/cloudinary-signature).',
        413,
        'PAYLOAD_TOO_LARGE'
      );
    }

    mediaUpload.single(fieldName)(req, res, (err) => {
      if (err) {
        if (err.code === 'LIMIT_FILE_SIZE') {
          return ApiResponse.error(res, 'File size exceeds allowed limit.', 413, 'LIMIT_FILE_SIZE');
        }
        return ApiResponse.error(res, err.message, 400);
      }
      next();
    });
  };
};

const uploadSingleApk = (fieldName = 'apkFile') => {
  return (req, res, next) => {
    apkUpload.single(fieldName)(req, res, (err) => {
      if (err) {
        if (err.code === 'LIMIT_FILE_SIZE') {
          return ApiResponse.error(res, 'APK file size exceeds the allowed upload limit (Max: 500MB).', 413, 'LIMIT_FILE_SIZE');
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
  uploadSingleApk,
};

