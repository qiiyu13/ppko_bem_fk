const router = require('express').Router();
const { body } = require('express-validator');
const controller = require('./appointments.controller');
const authenticate = require('../../middleware/auth');
const validate = require('../../middleware/validate');

router.use(authenticate);

router.get('/', controller.getAppointments);

router.post('/', [
  body('title').isString().notEmpty(),
  body('date').isISO8601(),
  validate,
], controller.createAppointment);

router.put('/:id', [
  body('title').optional().isString().notEmpty(),
  body('date').optional().isISO8601(),
  validate,
], controller.updateAppointment);

router.delete('/:id', controller.deleteAppointment);

module.exports = router;
