const multer = require('multer');

// Configure multer memory storage
const storage = multer.memoryStorage();

// File filter to allow only image types
const fileFilter = (req, file, cb) => {
  if (file.mimetype.startsWith('image/')) {
    cb(null, true);
  } else {
    cb(new Error('Invalid file type. Only image uploads are allowed.'), false);
  }
};

const mediaFilter = (req, file, cb) => {
  if (file.mimetype.startsWith('video/') || file.mimetype.startsWith('image/')) {
    cb(null, true);
  } else {
    cb(new Error('Invalid file type. Only video or image uploads are allowed.'), false);
  }
};

const upload = multer({
  storage: storage,
  fileFilter: fileFilter,
  limits: {
    fileSize: 5 * 1024 * 1024, // 5MB limit
  },
});

const mediaUpload = multer({
  storage: storage,
  fileFilter: mediaFilter,
  limits: {
    fileSize: 500 * 1024 * 1024, // 500MB limit for course videos
  },
});

module.exports = upload;
module.exports.mediaUpload = mediaUpload;
