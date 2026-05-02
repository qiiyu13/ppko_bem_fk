const router = require('express').Router();
const { body } = require('express-validator');
const controller = require('./chat.controller');
const authenticate = require('../../middleware/auth');
const validate = require('../../middleware/validate');

router.use(authenticate);

router.get('/conversations', controller.getConversations);
router.post('/conversations', controller.createConversation);

router.get('/conversations/:id/messages', controller.getMessages);
router.post('/conversations/:id/messages', [
  body('content').isString().notEmpty(),
  body('role').optional().isIn(['user', 'assistant']),
  validate,
], controller.sendMessage);

router.delete('/conversations/:id', controller.deleteConversation);

module.exports = router;
