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

router.get('/stats', controller.getStats);
router.get('/:id/users', controller.getUsersByRegion);

module.exports = router;
