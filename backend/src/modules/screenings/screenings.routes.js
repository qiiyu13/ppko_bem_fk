const router = require('express').Router();
const { body, query } = require('express-validator');
const controller = require('./screenings.controller');
const authenticate = require('../../middleware/auth');
const authorize = require('../../middleware/roleGuard');
const validate = require('../../middleware/validate');

// Genders the IRD calculation understands; anything else would silently get
// the female uric-acid denominator.
const GENDER_VALUES = ['pria', 'wanita', 'male', 'female', 'laki-laki'];
const { SCREENING_OPTION_FIELDS } = require('../../utils/healthOptions');

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
  // Only used to backfill birthDate for profiles that don't have one yet.
  body('age').optional({ values: 'null' }).isInt({ min: 0, max: 130 }),
  body('notes').optional({ values: 'null' }).isString().isLength({ max: 2000 }),
  body('screeningAt').optional({ values: 'null' }).isISO8601(),
  // Antropometri tambahan + nadi
  body('waistCircumference').optional({ values: 'null' }).isFloat({ min: 10, max: 300 }),
  body('abdominalCircumference').optional({ values: 'null' }).isFloat({ min: 10, max: 300 }),
  body('hipCircumference').optional({ values: 'null' }).isFloat({ min: 10, max: 300 }),
  body('pulse').optional({ values: 'null' }).isInt({ min: 20, max: 250 }),
  // Snapshot perilaku; falls back to the profile's current values when null
  ...Object.entries(SCREENING_OPTION_FIELDS).map(([field, values]) =>
    body(field).optional({ values: 'null' }).isIn(values)),
  body('sleepDuration').optional({ values: 'null' }).isFloat({ min: 0, max: 24 }),
  validate,
], controller.createScreening);

module.exports = router;
