const screeningsService = require('./screenings.service');
const { success, error, paginated } = require('../../utils/response');

const createScreening = async (req, res, next) => {
  try {
    const screening = await screeningsService.createScreening(req.body, req.user.id);
    return success(res, screening, 'Screening recorded successfully', 201);
  } catch (err) {
    if (err.message === 'Profile not found') return error(res, err.message, 404, 'NOT_FOUND');
    if (err.statusCode === 400) return error(res, err.message, 400, 'VALIDATION_ERROR');
    next(err);
  }
};

const getScreenings = async (req, res, next) => {
  try {
    const { profileId } = req.query;
    const result = await screeningsService.getScreenings(profileId, req.query);
    return paginated(res, result.data, result.total, result.page, result.limit);
  } catch (err) {
    next(err);
  }
};

const getStats = async (req, res, next) => {
  try {
    const stats = await screeningsService.getStats();
    return success(res, stats);
  } catch (err) {
    next(err);
  }
};

module.exports = { createScreening, getScreenings, getStats };
