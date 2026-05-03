const router = require('express').Router();
const { body } = require('express-validator');
const controller = require('./auth.controller');
const authenticate = require('../../middleware/auth');
const validate = require('../../middleware/validate');
const rateLimit = require('express-rate-limit');

const forgotPasswordLimiter = rateLimit({
  windowMs: 15 * 60 * 1000,
  max: 3,
  message: { success: false, error: { code: 'RATE_LIMIT', message: 'Too many reset requests. Try again later.' } },
});

const authLimiter = rateLimit({
  windowMs: 15 * 60 * 1000,
  max: 10,
  message: { success: false, error: { code: 'RATE_LIMIT', message: 'Too many attempts. Try again later.' } },
});

router.post('/register', [authLimiter,
  body('kkNumber').isString().matches(/^\d{16}$/).withMessage('KK number must be 16 digits'),
  body('responsibleName').isString().notEmpty(),
  body('password').isString().isLength({ min: 6 }),
  validate,
], controller.register);

router.post('/login', [authLimiter,
  body('kkNumber').isString().matches(/^\d{16}$/).withMessage('KK number must be 16 digits'),
  body('password').isString().notEmpty(),
  validate,
], controller.login);

router.get('/me', authenticate, controller.getMe);
router.post('/refresh', authenticate, controller.refreshToken);

router.post('/forgot-password', [forgotPasswordLimiter,
  body('kkNumber').isString().matches(/^\d{16}$/),
  body('phone').isString().notEmpty(),
  validate,
], controller.forgotPassword);

router.post('/reset-password', [
  body('kkNumber').isString().matches(/^\d{16}$/),
  body('firebaseToken').isString().notEmpty(),
  body('newPassword').isString().isLength({ min: 6 }),
  validate,
], controller.resetPassword);

router.post('/logout', authenticate, controller.logout);

module.exports = router;
