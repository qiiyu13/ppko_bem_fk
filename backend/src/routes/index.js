const router = require('express').Router();
const prisma = require('../utils/prisma');

// Health check
router.get('/health', async (req, res) => {
  try {
    await prisma.$queryRaw`SELECT 1`;
    res.json({ success: true, message: 'OK', timestamp: new Date().toISOString(), database: 'connected' });
  } catch (err) {
    res.status(503).json({ success: false, message: 'Service degraded', database: 'disconnected', timestamp: new Date().toISOString() });
  }
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
router.use('/notifications', require('../modules/notifications/notifications.routes'));
router.use('/public', require('../modules/public/public.routes'));

module.exports = router;