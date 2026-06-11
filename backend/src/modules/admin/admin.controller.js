const adminService = require('./admin.service');
const { success, error, paginated } = require('../../utils/response');

const getPatients = async (req, res, next) => {
  try {
    const { search, irdCategory, page, limit, regionId } = req.query;
    const result = await adminService.getPatients({ search, irdCategory, page, limit, regionId }, req.user);
    return paginated(res, result.data, result.total, result.page, result.limit, {
      totalHighRisk: result.totalHighRisk,
      totalAttention: result.totalAttention,
      totalNormal: result.totalNormal,
    });
  } catch (err) {
    next(err);
  }
};

const getPatientDetail = async (req, res, next) => {
  try {
    const patient = await adminService.getPatientDetail(req.params.id, req.user);
    return success(res, patient);
  } catch (err) {
    if (err.message === 'Patient not found') return error(res, err.message, 404, 'NOT_FOUND');
    next(err);
  }
};

module.exports = { getPatients, getPatientDetail };
