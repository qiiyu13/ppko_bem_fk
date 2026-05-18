const regionsService = require('./regions.service');
const { success, paginated } = require('../../utils/response');

const getRegions = async (req, res, next) => {
  try {
    const result = await regionsService.getRegions(req.query);
    return paginated(res, result.data, result.total, result.page, result.limit);
  } catch (err) {
    next(err);
  }
};

const createRegion = async (req, res, next) => {
  try {
    const region = await regionsService.createRegion(req.body);
    return success(res, region, 'Region created successfully', 201);
  } catch (err) {
    next(err);
  }
};

const getStats = async (req, res, next) => {
  try {
    const stats = await regionsService.getStats();
    return success(res, stats);
  } catch (err) {
    next(err);
  }
};

const getUsersByRegion = async (req, res, next) => {
  try {
    const result = await regionsService.getUsersByRegion(req.params.id, req.query);
    return paginated(res, result.data, result.total, result.page, result.limit);
  } catch (err) {
    next(err);
  }
};

module.exports = { getRegions, createRegion, getStats, getUsersByRegion };
