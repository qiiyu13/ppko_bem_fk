const router = require('express').Router();
const { body } = require('express-validator');
const adminController = require('./admin.controller');
const usersController = require('./users.controller');
const authenticate = require('../../middleware/auth');
const authorize = require('../../middleware/roleGuard');
const validate = require('../../middleware/validate');

router.use(authenticate, authorize('ADMIN', 'SUPERADMIN'));

// Dashboard
router.get('/patients', adminController.getPatients);
router.get('/patients/:id', adminController.getPatientDetail);

// User Management
router.get('/users', usersController.getUsers);
router.post('/users', [
  body('nik').isString().isLength({ min: 8, max: 16 }),
  body('name').isString().notEmpty(),
  body('password').isString().isLength({ min: 6 }),
  body('role').optional().isIn(['ADMIN', 'SUPERADMIN', 'PATIENT']),
  validate,
], usersController.createUser);
router.put('/users/:id', usersController.updateUser);
router.delete('/users/:id', usersController.deleteUser);

module.exports = router;
