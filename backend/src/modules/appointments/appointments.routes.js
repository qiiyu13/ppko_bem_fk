const router = require('express').Router();
const { body } = require('express-validator');
const controller = require('./appointments.controller');
const authenticate = require('../../middleware/auth');
const validate = require('../../middleware/validate');
const conflictDetection = require('../../middleware/conflictDetection');

router.use(authenticate);

router.get('/', controller.getAppointments);

router.get('/:id', controller.getAppointmentById);

router.post('/', [
  body('title').isString().notEmpty(),
  body('date').isISO8601(),
  validate,
], controller.createAppointment);

router.put('/:id', [
  body('title').optional().isString().notEmpty(),
  body('date').optional().isISO8601(),
  body('updatedAt').isISO8601().withMessage('updatedAt is required for conflict detection'),
  validate,
], conflictDetection('appointment'), controller.updateAppointment);

router.delete('/:id', [
  body('updatedAt').isISO8601().withMessage('updatedAt is required for conflict detection'),
  validate,
], conflictDetection('appointment'), controller.deleteAppointment);

module.exports = router;
