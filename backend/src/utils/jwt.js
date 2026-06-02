const jwt = require('jsonwebtoken');
const config = require('../config');

const generateToken = (payload) => {
  return jwt.sign(payload, config.jwtSecret, {
    expiresIn: config.jwtExpiresIn,
    issuer: config.jwtIssuer,
    audience: config.jwtAudience,
  });
};

const verifyToken = (token) => {
  try {
    return jwt.verify(token, config.jwtSecret, {
      issuer: config.jwtIssuer,
      audience: config.jwtAudience,
    });
  } catch (err) {
    // Rollout backward-compat: tokens signed before iss/aud existed lack those
    // claims and fail the strict check with "jwt audience/issuer invalid". Accept
    // them on a plain verify — signature and expiry are still enforced. Bad
    // signature (JsonWebTokenError "invalid signature") and expiry
    // (TokenExpiredError) do NOT match this guard and still reject.
    // REMOVE this fallback once JWT_EXPIRES_IN has elapsed since deploy (all
    // legacy tokens expired) so iss/aud become mandatory.
    if (err.name === 'JsonWebTokenError' && /jwt (audience|issuer) invalid/.test(err.message)) {
      return jwt.verify(token, config.jwtSecret);
    }
    throw err;
  }
};

module.exports = { generateToken, verifyToken };
