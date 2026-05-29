const usersService = require('./users.service');
const { success, error, paginated } = require('../../utils/response');

const getUsers = async (req, res, next) => {
  try {
    const { role } = req.query;
    const result = await usersService.getUsers(role, req.query);
    if (result && result.data !== undefined) {
      return paginated(res, result.data, result.total, result.page, result.limit);
    }
    return success(res, result);
  } catch (err) {
    next(err);
  }
};

const createUser = async (req, res, next) => {
  try {
    const user = await usersService.createUser(req.body);
    return success(res, user, 'User created successfully', 201);
  } catch (err) {
    if (err.code === 'P2002') return error(res, 'KK number already registered', 409, 'CONFLICT');
    next(err);
  }
};

const updateUser = async (req, res, next) => {
  try {
    const user = await usersService.updateUser(req.params.id, req.body);
    return success(res, user, 'User updated successfully');
  } catch (err) {
    if (err.code === 'P2025') return error(res, 'User not found', 404, 'NOT_FOUND');
    next(err);
  }
};

const deleteUser = async (req, res, next) => {
  try {
    const result = await usersService.deleteUser(req.params.id);
    return success(res, result);
  } catch (err) {
    if (err.code === 'P2025') return error(res, 'User not found', 404, 'NOT_FOUND');
    next(err);
  }
};

module.exports = { getUsers, createUser, updateUser, deleteUser };
