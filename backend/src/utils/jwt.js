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
  return jwt.verify(token, config.jwtSecret, {
    issuer: config.jwtIssuer,
    audience: config.jwtAudience,
  });
};

module.exports = { generateToken, verifyToken };
