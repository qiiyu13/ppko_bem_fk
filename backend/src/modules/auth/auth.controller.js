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
    if (err.message === 'Invalid credentials') return error(res, 'Invalid KK number or password', 401, 'INVALID_CREDENTIALS');
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
    if (err.statusCode === 404) return error(res, err.message, 404, 'NOT_FOUND');
    if (err.statusCode === 400) return error(res, err.message, 400, 'VALIDATION_ERROR');
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
    const user = await authService.getMe(req.user.id);
    const token = generateToken({ userId: user.id, role: user.role });
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

module.exports = { register, login, getMe, forgotPassword, resetPassword, refreshToken, logout };
