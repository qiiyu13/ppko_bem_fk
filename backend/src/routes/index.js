const router = require('express').Router();

// Health check
router.get('/health', (req, res) => {
  res.json({ success: true, message: 'OK', timestamp: new Date().toISOString() });
});

// Mount modules
router.use('/auth', require('../modules/auth/auth.routes'));
router.use('/profiles', require('../modules/profiles/profiles.routes'));
router.use('/metrics', require('../modules/metrics/metrics.routes'));
router.use('/articles', require('../modules/articles/articles.routes'));
router.use('/appointments', require('../modules/appointments/appointments.routes'));
router.use('/screenings', require('../modules/screenings/screenings.routes'));
router.use('/admin', require('../modules/admin/admin.routes'));
router.use('/regions', require('../modules/regions/regions.routes'));
router.use('/chat', require('../modules/chat/chat.routes'));

module.exports = router;
