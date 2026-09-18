const router = require('express').Router();
const { body } = require('express-validator');
const adminController = require('./admin.controller');
const usersController = require('./users.controller');
const kioskController = require('./kiosk.controller');
const { PROFILE_OPTION_FIELDS } = require('../../utils/healthOptions');
const authenticate = require('../../middleware/auth');
const authorize = require('../../middleware/roleGuard');
const validate = require('../../middleware/validate');
const conflictDetection = require('../../middleware/conflictDetection');

router.use(authenticate, authorize('ADMIN', 'SUPERADMIN'));

// Dashboard
router.get('/patients', adminController.getPatients);
router.get('/patients/:id', adminController.getPatientDetail);
router.get('/profiles/:id', adminController.getProfileDetail);

// User Management
router.get('/users', usersController.getUsers);
router.post('/users', [
  body('kkNumber').optional({ nullable: true }).isString().isLength({ min: 16, max: 16 }).withMessage('KK number must be exactly 16 digits'),
  body('username').optional({ nullable: true }).isString().isLength({ min: 3, max: 50 }).withMessage('Username must be 3-50 characters'),
  body('responsibleName').isString().notEmpty(),
  body('position').optional({ nullable: true }).isString().isLength({ max: 100 }),
  body('phone').optional({ nullable: true }).isString(),
  body('isActive').optional().isBoolean(),
  body('password').isString().isLength({ min: 6 }),
  body('role').optional().isIn(['ADMIN', 'SUPERADMIN', 'PATIENT']),
  body('regionId').optional({ nullable: true }).isString(),
  validate,
], usersController.createUser);

router.put('/users/:id', [
  body('updatedAt').isISO8601().withMessage('updatedAt is required for conflict detection'),
  validate,
], conflictDetection('user'), usersController.updateUser);

router.delete('/users/:id', [
  body('updatedAt').isISO8601().withMessage('updatedAt is required for conflict detection'),
  validate,
], conflictDetection('user'), usersController.deleteUser);

// Kiosk walk-in registration (screening-event front desk): six fields off an
// ID card in, KK/username/password + QR out. See kiosk.service.js.
router.post('/kiosk/register', [
  body('name').isString().trim().notEmpty().isLength({ max: 100 }),
  body('gender').customSanitizer((v) => typeof v === 'string' ? v.toLowerCase() : v).isIn(['pria', 'wanita']),
  body('nik').optional({ checkFalsy: true }).isString().trim().isLength({ min: 16, max: 16 }).withMessage('NIK must be exactly 16 digits'),
  body('occupation').optional({ checkFalsy: true }).isIn(PROFILE_OPTION_FIELDS.occupation),
  body('income').optional({ checkFalsy: true }).isFloat({ min: 0, max: 1e12 }),
  body('bloodType').optional({ checkFalsy: true }).isString().isLength({ max: 10 }),
  body('address').optional({ checkFalsy: true }).isString().isLength({ max: 500 }),
  validate,
], kioskController.registerWalkIn);

module.exports = router;
