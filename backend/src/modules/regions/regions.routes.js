const router = require('express').Router();
const { body } = require('express-validator');
const controller = require('./regions.controller');
const authenticate = require('../../middleware/auth');
const authorize = require('../../middleware/roleGuard');
const validate = require('../../middleware/validate');

router.use(authenticate, authorize('SUPERADMIN'));

router.get('/', controller.getRegions);
router.post('/', [
  body('type').isIn(['RW', 'RT']),
  body('name').isString().notEmpty(),
  validate,
], controller.createRegion);

router.get('/residents', controller.getResidents);
router.post('/residents', [
  body('regionId').isString().notEmpty(),
  body('name').isString().notEmpty(),
  body('nik').isString().notEmpty(),
  body('gender').isIn(['pria', 'wanita']),
  body('birthDate').isISO8601(),
  validate,
], controller.createResident);
router.put('/residents/:id', [
  body('name').optional().isString().notEmpty(),
  body('nik').optional().isString().notEmpty(),
  body('gender').optional().isIn(['pria', 'wanita']),
  body('birthDate').optional().isISO8601(),
  body('phone').optional({ nullable: true }).isString(),
  body('address').optional({ nullable: true }).isString(),
  validate,
], controller.updateResident);

module.exports = router;
