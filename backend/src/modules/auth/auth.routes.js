const router = require('express').Router();
const { body } = require('express-validator');
const controller = require('./auth.controller');
const authenticate = require('../../middleware/auth');
const validate = require('../../middleware/validate');

router.post('/register', [
  body('kkNumber').isString().matches(/^\d{16}$/).withMessage('KK number must be 16 digits'),
  body('responsibleName').isString().notEmpty(),
  body('password').isString().isLength({ min: 6 }),
  validate,
], controller.register);

router.post('/login', [
  body('kkNumber').isString().notEmpty(),
  body('password').isString().notEmpty(),
  validate,
], controller.login);

router.get('/me', authenticate, controller.getMe);

module.exports = router;
