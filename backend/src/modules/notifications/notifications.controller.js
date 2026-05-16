const service = require('./notifications.service');
const { success, error } = require('../../utils/response');

const registerToken = async (req, res, next) => {
  try {
    const result = await service.registerToken(req.user.id, req.body.fcmToken);
    return success(res, result);
  } catch (err) {
    next(err);
  }
};

const getNotifications = async (req, res, next) => {
  try {
    const list = await service.getNotifications(req.user.id);
    return success(res, list);
  } catch (err) {
    next(err);
  }
};

const markAllRead = async (req, res, next) => {
  try {
    const result = await service.markAllRead(req.user.id);
    return success(res, result);
  } catch (err) {
    next(err);
  }
};

const markRead = async (req, res, next) => {
  try {
    const result = await service.markRead(req.params.id, req.user.id);
    return success(res, result);
  } catch (err) {
    if (err.message === 'Notification not found') return error(res, err.message, 404, 'NOT_FOUND');
    next(err);
  }
};

module.exports = { registerToken, getNotifications, markAllRead, markRead };
