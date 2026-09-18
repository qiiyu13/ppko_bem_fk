const path = require('path');
const QRCode = require('qrcode');
const sharp = require('sharp');

// Same payload shape the Flutter app's profile QR dialog encodes
// (lib/widgets/profile_qr_dialog.dart) and its admin scanner decodes
// (lib/screens/admin/qr_scanner_screen.dart) - keep the two in sync.
const profileQrPayload = (profile) => JSON.stringify({
  profileId: profile.id,
  name: profile.name,
  nik: profile.nik,
});

const QR_SIZE = 300;
const LOGO_PATH = path.join(__dirname, '../assets/logo_only.png');

const toDataUrl = (payload) => QRCode.toDataURL(payload, { errorCorrectionLevel: 'H', margin: 1, width: QR_SIZE });

// Same look as the app's own QR dialog (embeds assets/icon/logo_only.png in
// the center via qr_flutter's embeddedImage). errorCorrectionLevel 'H'
// tolerates ~30% of the code being obscured; the logo + its white backing
// stays under 26% of the width here, so it still scans.
const toBrandedDataUrl = async (payload) => {
  const qrBuffer = await QRCode.toBuffer(payload, { errorCorrectionLevel: 'H', margin: 1, width: QR_SIZE, type: 'png' });

  const logoSize = Math.round(QR_SIZE * 0.18);
  const backingSize = Math.round(logoSize * 1.3);

  const logo = await sharp(LOGO_PATH).resize(logoSize, logoSize).toBuffer();
  const backing = await sharp({
    create: { width: backingSize, height: backingSize, channels: 4, background: { r: 255, g: 255, b: 255, alpha: 1 } },
  }).composite([{ input: logo, gravity: 'center' }]).png().toBuffer();

  const branded = await sharp(qrBuffer).composite([{ input: backing, gravity: 'center' }]).png().toBuffer();
  return `data:image/png;base64,${branded.toString('base64')}`;
};

module.exports = { profileQrPayload, toDataUrl, toBrandedDataUrl };
