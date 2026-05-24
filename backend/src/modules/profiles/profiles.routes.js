const router = require('express').Router();
const { body } = require('express-validator');
const controller = require('./profiles.controller');
const authenticate = require('../../middleware/auth');
const validate = require('../../middleware/validate');
const conflictDetection = require('../../middleware/conflictDetection');

const { uploadAvatarMiddleware } = require('../../config/multer');

router.use(authenticate);

router.get('/', controller.getProfiles);
router.get('/:id', controller.getProfile);

router.post('/', uploadAvatarMiddleware, [
  body('name').isString().notEmpty(),
  body('nik').isString().notEmpty(),
  body('gender').customSanitizer((v) => typeof v === 'string' ? v.toLowerCase() : v).isIn(['pria', 'wanita']),
  body('birthDate').isISO8601(),
  validate,
], controller.createProfile);

router.put('/:id', uploadAvatarMiddleware, [
  body('name').optional().isString().notEmpty(),
  body('nik').optional().isString().notEmpty(),
  body('gender').optional().customSanitizer((v) => typeof v === 'string' ? v.toLowerCase() : v).isIn(['pria', 'wanita']),
  body('birthDate').optional().isISO8601(),
  body('updatedAt').isISO8601().withMessage('updatedAt is required for conflict detection'),
  validate,
], conflictDetection('familyProfile'), controller.updateProfile);

router.delete('/:id', [
  body('updatedAt').isISO8601().withMessage('updatedAt is required for conflict detection'),
  validate,
], conflictDetection('familyProfile'), controller.deleteProfile);

module.exports = router;
