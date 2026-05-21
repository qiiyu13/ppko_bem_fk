const metricsService = require('./metrics.service');
const { success, error, paginated } = require('../../utils/response');

const getMetrics = async (req, res, next) => {
  try {
    const { profileId } = req.query;
    if (!profileId) return error(res, 'profileId is required', 400, 'VALIDATION_ERROR');

    const result = await metricsService.getMetrics(profileId, req.user.id, req.query);
    return paginated(res, result.data, result.total, result.page, result.limit);
  } catch (err) {
    if (err.message === 'Profile not found') return error(res, err.message, 404, 'NOT_FOUND');
    next(err);
  }
};

const createMetric = async (req, res, next) => {
  try {
    const metric = await metricsService.createMetric(req.body, req.user.id);
    return success(res, metric, 'Metric recorded successfully', 201);
  } catch (err) {
    if (err.message === 'Profile not found') return error(res, err.message, 404, 'NOT_FOUND');
    next(err);
  }
};

const getHistory = async (req, res, next) => {
  try {
    const { profileId } = req.query;
    if (!profileId) return error(res, 'profileId is required', 400, 'VALIDATION_ERROR');

    const result = await metricsService.getHistory(profileId, req.params.type, req.user.id, req.query);
    if (result && result.data !== undefined) {
      return paginated(res, result.data, result.total, result.page, result.limit);
    }
    return success(res, result);
  } catch (err) {
    if (err.message === 'Profile not found') return error(res, err.message, 404, 'NOT_FOUND');
    next(err);
  }
};

const getLatest = async (req, res, next) => {
  try {
    const { profileId } = req.query;
    if (!profileId) return error(res, 'profileId is required', 400, 'VALIDATION_ERROR');

    const latest = await metricsService.getLatest(profileId, req.user.id);
    return success(res, latest);
  } catch (err) {
    if (err.message === 'Profile not found') return error(res, err.message, 404, 'NOT_FOUND');
    next(err);
  }
};

module.exports = { getMetrics, createMetric, getHistory, getLatest };
