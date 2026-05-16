const router = require('express').Router();
const { body } = require('express-validator');
const controller = require('./screenings.controller');
const authenticate = require('../../middleware/auth');
const authorize = require('../../middleware/roleGuard');
const validate = require('../../middleware/validate');

router.get('/', authenticate, controller.getScreenings);
router.get('/stats', authenticate, authorize('ADMIN', 'SUPERADMIN'), controller.getStats);

router.post('/', authenticate, authorize('ADMIN', 'SUPERADMIN'), [
  body('profileId').isString().notEmpty(),
  body('systolic').isInt({ min: 0 }),
  body('diastolic').isInt({ min: 0 }),
  body('bloodSugar').optional().isFloat({ min: 0 }),
  body('cholesterol').optional().isFloat({ min: 0 }),
  body('uricAcid').optional().isFloat({ min: 0 }),
  validate,
], controller.createScreening);

module.exports = router;
