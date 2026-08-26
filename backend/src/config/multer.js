const multer = require('multer');
const path = require('path');

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

const VIDEO_EXTENSIONS = new Set([
  '.mp4', '.m4v', '.mp4v',
  '.mkv',
  '.mov', '.qt',
  '.avi',
  '.webm',
  '.flv', '.f4v', '.f4p', '.f4a', '.f4b',
  '.wmv', '.asf',
  '.3gp', '.3g2',
  '.mpeg', '.mpg', '.m2v', '.mp2', '.mpv',
  '.ts', '.mts', '.m2ts',
  '.ogv', '.ogg',
  '.vob',
  '.divx', '.xvid',
  '.rm', '.rmvb'
]);
const IMAGE_EXTENSIONS = new Set(['.jpg', '.jpeg', '.png', '.gif', '.webp', '.bmp', '.svg', '.tiff']);

const mediaFilter = (req, file, cb) => {
  const mime = (file.mimetype || '').toLowerCase();
  const ext = path.extname(file.originalname || '').toLowerCase();

  const mimeOk = mime.startsWith('video/') || mime.startsWith('image/') || mime === 'application/octet-stream' || mime.includes('matroska') || mime.includes('quicktime');
  const extOk = VIDEO_EXTENSIONS.has(ext) || IMAGE_EXTENSIONS.has(ext);

  if (mimeOk || extOk || !ext) {
    cb(null, true);
  } else {
    cb(new Error(`Invalid file format (${ext || mime}). Allowed video formats include MP4, MKV, MOV, AVI, WEBM, FLV, WMV, 3GP, MPEG, TS, OGV, VOB, etc.`), false);
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
    fileSize: 1024 * 1024 * 1024, // 1GB limit
  },
});

const apkUpload = multer({
  storage: storage,
  fileFilter: (req, file, cb) => {
    const ext = path.extname(file.originalname || '').toLowerCase();
    const mime = (file.mimetype || '').toLowerCase();
    const mimeOk = mime.includes('android') || mime.includes('package-archive') || mime === 'application/octet-stream' || mime.includes('zip') || mime.includes('x-zip');
    const extOk = ext === '.apk' || ext === '.aab' || ext === '.zip';

    if (mimeOk || extOk || !ext) {
      cb(null, true);
    } else {
      cb(new Error('Invalid file type. Only .apk or .aab Android package files are allowed.'), false);
    }
  },
  limits: {
    fileSize: 500 * 1024 * 1024, // 500MB limit
  },
});

module.exports = upload;
module.exports.mediaUpload = mediaUpload;
module.exports.apkUpload = apkUpload;
