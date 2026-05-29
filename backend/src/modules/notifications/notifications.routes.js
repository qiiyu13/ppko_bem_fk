const router = require('express').Router();
const { body } = require('express-validator');
const controller = require('./notifications.controller');
const authenticate = require('../../middleware/auth');
const validate = require('../../middleware/validate');

router.use(authenticate);

router.post('/register-token', [
  body('fcmToken').isString().notEmpty(),
  validate,
], controller.registerToken);

router.get('/', controller.getNotifications);

router.post('/mark-all-read', controller.markAllRead);

router.delete('/', controller.deleteAll);

router.post('/:id/read', controller.markRead);

module.exports = router;
