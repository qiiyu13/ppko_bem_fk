const QRCode = require('qrcode');

// Same payload shape the Flutter app's profile QR dialog encodes
// (lib/widgets/profile_qr_dialog.dart) and its admin scanner decodes
// (lib/screens/admin/qr_scanner_screen.dart) - keep the two in sync.
const profileQrPayload = (profile) => JSON.stringify({
  profileId: profile.id,
  name: profile.name,
  nik: profile.nik,
});

const toDataUrl = (payload) => QRCode.toDataURL(payload, { errorCorrectionLevel: 'H', margin: 1, width: 300 });

module.exports = { profileQrPayload, toDataUrl };
