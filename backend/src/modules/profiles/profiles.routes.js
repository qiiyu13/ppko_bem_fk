const router = require('express').Router();
const { body } = require('express-validator');
const controller = require('./profiles.controller');
const authenticate = require('../../middleware/auth');
const validate = require('../../middleware/validate');

router.use(authenticate);

router.get('/', controller.getProfiles);
router.get('/:id', controller.getProfile);

router.post('/', [
  body('name').isString().notEmpty(),
  body('nik').isString().notEmpty(),
  body('gender').isIn(['pria', 'wanita']),
  body('birthDate').isISO8601(),
  validate,
], controller.createProfile);

router.put('/:id', [
  body('name').optional().isString().notEmpty(),
  body('nik').optional().isString().notEmpty(),
  body('gender').optional().isIn(['pria', 'wanita']),
  body('birthDate').optional().isISO8601(),
  validate,
], controller.updateProfile);

router.delete('/:id', controller.deleteProfile);

module.exports = router;
