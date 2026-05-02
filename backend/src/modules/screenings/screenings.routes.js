const router = require('express').Router();
const { body } = require('express-validator');
const controller = require('./screenings.controller');
const authenticate = require('../../middleware/auth');
const authorize = require('../../middleware/roleGuard');
const validate = require('../../middleware/validate');

router.use(authenticate, authorize('ADMIN', 'SUPERADMIN'));

router.post('/', [
  body('profileId').isString().notEmpty(),
  body('systolic').isInt({ min: 0 }),
  body('diastolic').isInt({ min: 0 }),
  body('bloodSugar').isFloat({ min: 0 }),
  body('cholesterol').isFloat({ min: 0 }),
  body('uricAcid').isFloat({ min: 0 }),
  validate,
], controller.createScreening);

router.get('/', controller.getScreenings);
router.get('/stats', controller.getStats);

module.exports = router;
