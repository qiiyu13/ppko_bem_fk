const router = require('express').Router();
const { body } = require('express-validator');
const controller = require('./articles.controller');
const authenticate = require('../../middleware/auth');
const authorize = require('../../middleware/roleGuard');
const validate = require('../../middleware/validate');
const conflictDetection = require('../../middleware/conflictDetection');
const { uploadArticleImageMiddleware } = require('../../config/multer');

// Admin routes (must be before /:id to avoid matching "admin" as an id)
router.get('/admin/all', authenticate, authorize('ADMIN', 'SUPERADMIN'), controller.getAllArticles);

router.post('/admin/image', authenticate, authorize('ADMIN', 'SUPERADMIN'), uploadArticleImageMiddleware, controller.uploadImage);

// Public routes
router.get('/', controller.getPublishedArticles);
router.get('/:id', controller.getPublishedArticle);

router.post('/admin', authenticate, authorize('ADMIN', 'SUPERADMIN'), [
  body('title').isString().notEmpty(),
  body('content').isString().notEmpty(),
  validate,
], controller.createArticle);

router.put('/admin/:id', authenticate, authorize('ADMIN', 'SUPERADMIN'), [
  body('updatedAt').isISO8601().withMessage('updatedAt is required for conflict detection'),
  validate,
], conflictDetection('article'), controller.updateArticle);

router.delete('/admin/:id', authenticate, authorize('ADMIN', 'SUPERADMIN'), [
  body('updatedAt').isISO8601().withMessage('updatedAt is required for conflict detection'),
  validate,
], conflictDetection('article'), controller.deleteArticle);

router.patch('/admin/:id/publish', authenticate, authorize('ADMIN', 'SUPERADMIN'), [
  body('updatedAt').isISO8601().withMessage('updatedAt is required for conflict detection'),
  validate,
], conflictDetection('article'), controller.publishArticle);

module.exports = router;
