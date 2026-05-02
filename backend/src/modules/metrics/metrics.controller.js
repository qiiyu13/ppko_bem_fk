const metricsService = require('./metrics.service');
const { success, error } = require('../../utils/response');

const getMetrics = async (req, res, next) => {
  try {
    const { profileId } = req.query;
    if (!profileId) return error(res, 'profileId is required', 400, 'VALIDATION_ERROR');

    const metrics = await metricsService.getMetrics(profileId, req.user.id);
    return success(res, metrics);
  } catch (err) {
    if (err.message === 'Profile not found') return error(res, err.message, 404, 'NOT_FOUND');
    next(err);
  }
};

const createMetric = async (req, res, next) => {
  try {
    const metric = await metricsService.createMetric(req.body);
    return success(res, metric, 'Metric recorded successfully', 201);
  } catch (err) {
    next(err);
  }
};

const getHistory = async (req, res, next) => {
  try {
    const { profileId } = req.query;
    if (!profileId) return error(res, 'profileId is required', 400, 'VALIDATION_ERROR');

    const history = await metricsService.getHistory(profileId, req.params.type, req.user.id);
    return success(res, history);
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
