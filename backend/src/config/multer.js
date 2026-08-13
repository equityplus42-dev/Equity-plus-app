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

const path = require('path');

const VIDEO_EXTENSIONS = new Set(['.mp4', '.mov', '.avi', '.mkv', '.webm', '.flv', '.wmv', '.m4v', '.3gp', '.mpeg', '.mpg']);
const IMAGE_EXTENSIONS = new Set(['.jpg', '.jpeg', '.png', '.gif', '.webp', '.bmp', '.svg', '.tiff']);

const mediaFilter = (req, file, cb) => {
  const mimeOk = file.mimetype.startsWith('video/') || file.mimetype.startsWith('image/');
  const ext = path.extname(file.originalname).toLowerCase();
  const extOk = VIDEO_EXTENSIONS.has(ext) || IMAGE_EXTENSIONS.has(ext);

  if (mimeOk || extOk) {
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
    fileSize: 1024 * 1024 * 1024, // 1GB limit (videos <= 100MB go to Dedicated Cloudinary Video; videos > 100MB auto-route to Cloudflare R2)
  },
});

module.exports = upload;
module.exports.mediaUpload = mediaUpload;
