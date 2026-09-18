const router = require('express').Router();
const { body } = require('express-validator');
const controller = require('./profiles.controller');
const authenticate = require('../../middleware/auth');
const validate = require('../../middleware/validate');
const conflictDetection = require('../../middleware/conflictDetection');
const { PROFILE_OPTION_FIELDS } = require('../../utils/healthOptions');

// Health variables (demografi + gaya hidup). All optional; multipart forms
// send '' for unset fields, so any falsy value means "not provided".
const healthVariableValidators = [
  ...Object.entries(PROFILE_OPTION_FIELDS).map(([field, values]) =>
    body(field).optional({ checkFalsy: true }).isIn(values)),
  body('income').optional({ checkFalsy: true }).isFloat({ min: 0, max: 1e12 }),
  body('sleepDuration').optional({ checkFalsy: true }).isFloat({ min: 0, max: 24 }),
];

const { uploadAvatarMiddleware } = require('../../config/multer');

router.use(authenticate);

router.get('/', controller.getProfiles);
router.get('/:id', controller.getProfile);

router.post('/', uploadAvatarMiddleware, [
  body('name').isString().notEmpty(),
  body('nik').optional({ nullable: true }).isString().notEmpty(),
  body('gender').customSanitizer((v) => typeof v === 'string' ? v.toLowerCase() : v).isIn(['pria', 'wanita']),
  body('birthDate').optional({ nullable: true }).isISO8601(),
  body('address').optional({ nullable: true, checkFalsy: true }).isString().isLength({ max: 500 }),
  ...healthVariableValidators,
  validate,
], controller.createProfile);

router.put('/:id', uploadAvatarMiddleware, [
  body('name').optional().isString().notEmpty(),
  body('nik').optional().isString().notEmpty(),
  body('gender').optional().customSanitizer((v) => typeof v === 'string' ? v.toLowerCase() : v).isIn(['pria', 'wanita']),
  body('birthDate').optional().isISO8601(),
  body('address').optional({ checkFalsy: true }).isString().isLength({ max: 500 }),
  ...healthVariableValidators,
  body('updatedAt').isISO8601().withMessage('updatedAt is required for conflict detection'),
  validate,
], conflictDetection('familyProfile'), controller.updateProfile);

router.delete('/:id', [
  body('updatedAt').isISO8601().withMessage('updatedAt is required for conflict detection'),
  validate,
], conflictDetection('familyProfile'), controller.deleteProfile);

module.exports = router;
