const kioskService = require('./kiosk.service');
const { toDataUrl } = require('../../utils/qr');
const { success, error } = require('../../utils/response');

const registerWalkIn = async (req, res, next) => {
  try {
    const result = await kioskService.registerWalkIn(req.body);

    // Same-origin page that shows the QR again on the patient's own phone
    // (see public/my-account.html) - built from the request, not a config
    // constant, so it works unchanged on every host this API is deployed to.
    const viewUrl = `${req.protocol}://${req.get('host')}/my-account.html?t=${result.viewToken}`;

    const [qrDataUrl, viewQrDataUrl] = await Promise.all([
      toDataUrl(result.qrPayload),
      toDataUrl(viewUrl),
    ]);

    return success(res, {
      kkNumber: result.kkNumber,
      username: result.username,
      password: result.password,
      profile: result.profile,
      qrDataUrl,
      viewUrl,
      viewQrDataUrl,
    }, 'Account created', 201);
  } catch (err) {
    if (err.statusCode === 409) return error(res, err.message, 409, 'CONFLICT');
    next(err);
  }
};

module.exports = { registerWalkIn };
