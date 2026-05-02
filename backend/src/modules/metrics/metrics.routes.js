const router = require('express').Router();
const { body } = require('express-validator');
const controller = require('./metrics.controller');
const authenticate = require('../../middleware/auth');
const validate = require('../../middleware/validate');

router.use(authenticate);

router.get('/', controller.getMetrics);

router.post('/', [
  body('profileId').isString().notEmpty(),
  body('type').isString().notEmpty(),
  body('value').isFloat(),
  body('unit').isString().notEmpty(),
  validate,
], controller.createMetric);

router.get('/:type/history', controller.getHistory);
router.get('/latest', controller.getLatest);

module.exports = router;
