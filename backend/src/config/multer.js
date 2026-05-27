const multer = require('multer');
const path = require('path');
const fs = require('fs');
const sharp = require('sharp');

const avatarsDir = path.resolve(__dirname, '../../uploads/avatars');
const articlesDir = path.resolve(__dirname, '../../uploads/articles');
fs.mkdirSync(avatarsDir, { recursive: true });
fs.mkdirSync(articlesDir, { recursive: true });

const fileFilter = (req, file, cb) => {
  const allowed = /\.(jpg|jpeg|png|webp)$/i;
  const ext = path.extname(file.originalname);
  if (allowed.test(ext)) {
    cb(null, true);
  } else {
    cb(new Error('Only .jpg, .jpeg, .png, .webp files are allowed'), false);
  }
};

const makeStorage = (dir, prefix) => multer.diskStorage({
  destination: (req, file, cb) => cb(null, dir),
  filename: (req, file, cb) => {
    const uniqueSuffix = `${Date.now()}-${Math.round(Math.random() * 1e9)}`;
    cb(null, `${prefix}-${uniqueSuffix}${path.extname(file.originalname)}`);
  },
});

const makeUploadMiddleware = (storage, field) => {
  const upload = multer({ storage, fileFilter, limits: { fileSize: 5 * 1024 * 1024 } }).single(field);
  return (req, res, next) => {
    upload(req, res, (err) => {
      if (err) {
        return res.status(400).json({
          success: false,
          error: { code: 'FILE_ERROR', message: err.message },
        });
      }
      next();
    });
  };
};

// Resize/compress uploaded avatar to a small webp. Filenames stay unique, so
// downstream path-building (req.file.filename) keeps working unchanged.
const processAvatar = async (req, res, next) => {
  if (!req.file) return next();
  const original = req.file.path;
  try {
    const outName = `avatar-${Date.now()}-${Math.round(Math.random() * 1e9)}.webp`;
    const outPath = path.join(avatarsDir, outName);
    await sharp(original)
      .rotate()
      .resize(256, 256, { fit: 'cover', position: 'centre' })
      .webp({ quality: 80 })
      .toFile(outPath);
    fs.unlink(original, () => {});
    req.file.filename = outName;
    req.file.path = outPath;
    next();
  } catch (err) {
    fs.unlink(original, () => {});
    return res.status(400).json({
      success: false,
      error: { code: 'IMAGE_ERROR', message: 'Gagal memproses gambar' },
    });
  }
};

const uploadAvatarMiddleware = [
  makeUploadMiddleware(makeStorage(avatarsDir, 'avatar'), 'avatar'),
  processAvatar,
];
const uploadArticleImageMiddleware = makeUploadMiddleware(makeStorage(articlesDir, 'article'), 'image');

module.exports = { uploadAvatarMiddleware, uploadArticleImageMiddleware };
