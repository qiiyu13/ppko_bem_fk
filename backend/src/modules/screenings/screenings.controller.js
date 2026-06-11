const screeningsService = require('./screenings.service');
const { success, error, paginated } = require('../../utils/response');

const createScreening = async (req, res, next) => {
  try {
    const screening = await screeningsService.createScreening(req.body, req.user.id, req.user.role);
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
    const result = await screeningsService.getScreenings(profileId, req.query, req.user);
    return paginated(res, result.data, result.total, result.page, result.limit);
  } catch (err) {
    next(err);
  }
};

const getStats = async (req, res, next) => {
  try {
    const stats = await screeningsService.getStats(req.user);
    return success(res, stats);
  } catch (err) {
    next(err);
  }
};

const getScreeningReport = async (req, res, next) => {
  try {
    const { from, to } = req.query;
    // ADMIN can only see their own screenings; SUPERADMIN may filter by one admin or see all.
    const screenedBy = req.user.role === 'SUPERADMIN'
      ? (req.query.screenedBy || undefined)
      : req.user.id;
    const { rows, truncated } = await screeningsService.getScreeningReport({ screenedBy, from, to });
    // `data` stays a plain array so app builds predating `meta` keep working.
    return res.status(200).json({ success: true, data: rows, meta: { total: rows.length, truncated } });
  } catch (err) {
    next(err);
  }
};

module.exports = { createScreening, getScreenings, getStats, getScreeningReport };
