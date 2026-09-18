const publicService = require('./public.service');
const { success, error } = require('../../utils/response');

const getProfileByToken = async (req, res, next) => {
  try {
    const data = await publicService.getProfileByViewToken(req.params.token);
    return success(res, data);
  } catch (err) {
    if (err.statusCode) return error(res, err.message, err.statusCode, err.statusCode === 404 ? 'NOT_FOUND' : 'INVALID_TOKEN');
    next(err);
  }
};

module.exports = { getProfileByToken };
