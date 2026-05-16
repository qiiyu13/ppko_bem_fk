const { verifyToken } = require('../utils/jwt');
const { error } = require('../utils/response');
const { isBlacklisted } = require('../modules/auth/tokenBlacklist');

const authenticate = (req, res, next) => {
  const authHeader = req.headers.authorization;

  if (!authHeader || !authHeader.startsWith('Bearer ')) {
    return error(res, 'Access token required', 401, 'UNAUTHORIZED');
  }

  const token = authHeader.split(' ')[1];

  if (isBlacklisted(token)) {
    return error(res, 'Token has been revoked', 401, 'TOKEN_REVOKED');
  }

  try {
    const decoded = verifyToken(token);
    req.user = { id: decoded.userId, role: decoded.role };
    next();
  } catch (err) {
    return error(res, 'Invalid or expired token', 401, 'INVALID_TOKEN');
  }
};

module.exports = authenticate;

