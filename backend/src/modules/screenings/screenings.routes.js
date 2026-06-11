const router = require('express').Router();
const { body, query } = require('express-validator');
const controller = require('./screenings.controller');
const authenticate = require('../../middleware/auth');
const authorize = require('../../middleware/roleGuard');
const validate = require('../../middleware/validate');

// Genders the IRD calculation understands; anything else would silently get
// the female uric-acid denominator.
const GENDER_VALUES = ['pria', 'wanita', 'male', 'female', 'laki-laki'];

router.get('/', authenticate, controller.getScreenings);
router.get('/stats', authenticate, authorize('ADMIN', 'SUPERADMIN'), controller.getStats);
router.get('/report', authenticate, authorize('ADMIN', 'SUPERADMIN'), [
  query('from').optional().isISO8601(),
  query('to').optional().isISO8601(),
  query('screenedBy').optional().isString().notEmpty(),
  validate,
], controller.getScreeningReport);

// The form sends explicit nulls for empty optional fields, hence { values: 'null' }.
router.post('/', authenticate, authorize('ADMIN', 'SUPERADMIN'), [
  body('profileId').isString().notEmpty(),
  body('systolic').isInt({ min: 40, max: 300 }),
  body('diastolic').isInt({ min: 20, max: 200 }),
  body('bloodSugar').optional({ values: 'null' }).isFloat({ min: 0, max: 1000 }),
  body('cholesterol').optional({ values: 'null' }).isFloat({ min: 0, max: 1000 }),
  body('uricAcid').optional({ values: 'null' }).isFloat({ min: 0, max: 50 }),
  body('height').optional({ values: 'null' }).isFloat({ min: 30, max: 300 }),
  body('weight').optional({ values: 'null' }).isFloat({ min: 1, max: 500 }),
  body('gender').optional({ values: 'null' }).custom((v) => GENDER_VALUES.includes(String(v).toLowerCase())),
  body('notes').optional({ values: 'null' }).isString().isLength({ max: 2000 }),
  body('screeningAt').optional({ values: 'null' }).isISO8601(),
  validate,
], controller.createScreening);

module.exports = router;
