const multer = require('multer');
const path = require('path');

const uploadsDir = path.resolve(__dirname, '../../uploads/avatars');

const storage = multer.diskStorage({
  destination: (req, file, cb) => {
    cb(null, uploadsDir);
  },
  filename: (req, file, cb) => {
    const uniqueSuffix = `${Date.now()}-${Math.round(Math.random() * 1e9)}`;
    const ext = path.extname(file.originalname);
    cb(null, `avatar-${uniqueSuffix}${ext}`);
  },
});

const fileFilter = (req, file, cb) => {
  const allowed = /\.(jpg|jpeg|png|webp)$/i;
  const ext = path.extname(file.originalname);
  if (allowed.test(ext)) {
    cb(null, true);
  } else {
    cb(new Error('Only .jpg, .jpeg, .png, .webp files are allowed'), false);
  }
};

const uploadAvatar = multer({
  storage,
  fileFilter,
  limits: { fileSize: 5 * 1024 * 1024 },
}).single('avatar');

const uploadAvatarMiddleware = (req, res, next) => {
  uploadAvatar(req, res, (err) => {
    if (err) {
      if (err instanceof multer.MulterError) {
        return res.status(400).json({
          success: false,
          error: { code: 'FILE_ERROR', message: err.message },
        });
      }
      return res.status(400).json({
        success: false,
        error: { code: 'FILE_ERROR', message: err.message },
      });
    }
    next();
  });
};

module.exports = { uploadAvatarMiddleware };
