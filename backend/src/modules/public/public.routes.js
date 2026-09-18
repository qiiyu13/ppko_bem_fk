const router = require('express').Router();
const controller = require('./public.controller');

// No authenticate() here on purpose - this is the "scan the QR again on your
// own phone" page from the kiosk flow, gated only by the unguessable signed
// token (see public.service.js).
router.get('/profile-qr/:token', controller.getProfileByToken);

module.exports = router;
