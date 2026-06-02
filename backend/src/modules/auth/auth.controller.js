const authService = require('./auth.service');
const { success, error } = require('../../utils/response');

const register = async (req, res, next) => {
  try {
    const result = await authService.register(req.body);
    return success(res, result, 'Registration successful', 201);
  } catch (err) {
    if (err.code === 'P2002') return error(res, 'KK number already registered', 409, 'CONFLICT');
    next(err);
  }
};

const login = async (req, res, next) => {
  try {
    const result = await authService.login(req.body);
    return success(res, result, 'Login successful');
  } catch (err) {
    if (err.message === 'Invalid credentials') return error(res, 'Invalid credentials', 401, 'INVALID_CREDENTIALS');
    next(err);
  }
};

const getMe = async (req, res, next) => {
  try {
    const user = await authService.getMe(req.user.id);
    return success(res, user);
  } catch (err) {
    next(err);
  }
};

const forgotPassword = async (req, res, next) => {
  try {
    const result = await authService.forgotPassword(req.body);
    return success(res, result);
  } catch (err) {
    next(err);
  }
};

const resetPassword = async (req, res, next) => {
  try {
    const result = await authService.resetPassword(req.body);
    return success(res, result);
  } catch (err) {
    if (err.statusCode === 400) return error(res, err.message, 400, 'VALIDATION_ERROR');
    next(err);
  }
};

const refreshToken = async (req, res, next) => {
  try {
    const { generateToken } = require('../../utils/jwt');
    const config = require('../../config');

    const account = await authService.getAccountStatus(req.user.id);
    if (!account) return error(res, 'Invalid or expired token', 401, 'INVALID_TOKEN');
    // Deactivated accounts can no longer mint fresh tokens. Their current token
    // keeps working until it expires (sliding window) — closing that residual
    // gap fully needs a per-request isActive check or a shorter token TTL.
    if (!account.isActive) return error(res, 'Account is deactivated', 403, 'ACCOUNT_DISABLED');

    // Absolute session cap: authAt is the original login time. Tokens issued
    // before this claim existed fall back to their issue time (iat).
    const claims = req.tokenClaims || {};
    const authAt = claims.authAt || claims.iat;
    if (authAt && (Math.floor(Date.now() / 1000) - authAt) > config.maxSessionAge) {
      return error(res, 'Session expired. Please log in again.', 401, 'SESSION_EXPIRED');
    }

    const token = generateToken({ userId: account.id, role: account.role, authAt });
    return success(res, { token });
  } catch (err) {
    next(err);
  }
};

const logout = async (req, res, next) => {
  try {
    const token = req.headers.authorization.split(' ')[1];
    const decoded = require('../../utils/jwt').verifyToken(token);
    await require('./tokenBlacklist').blacklistToken(token, decoded.exp * 1000);
    return success(res, null, 'Logged out successfully');
  } catch (err) {
    next(err);
  }
};

const updatePicture = async (req, res, next) => {
  try {
    if (!req.file) {
      return error(res, 'No file uploaded', 400, 'FILE_REQUIRED');
    }
    const avatarPath = `/uploads/avatars/${req.file.filename}`;
    await authService.updateAvatar(req.user.id, avatarPath);
    return success(res, { avatarPath }, 'Picture updated');
  } catch (err) {
    next(err);
  }
};

module.exports = { register, login, getMe, forgotPassword, resetPassword, refreshToken, logout, updatePicture };
