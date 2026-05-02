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

module.exports = { register, login, getMe };
