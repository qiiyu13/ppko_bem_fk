const regionsService = require('./regions.service');
const { success, error } = require('../../utils/response');

const getRegions = async (req, res, next) => {
  try {
    const regions = await regionsService.getRegions();
    return success(res, regions);
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

const getResidents = async (req, res, next) => {
  try {
    const { regionId } = req.query;
    const residents = await regionsService.getResidents(regionId);
    return success(res, residents);
  } catch (err) {
    next(err);
  }
};

const createResident = async (req, res, next) => {
  try {
    const resident = await regionsService.createResident(req.body);
    return success(res, resident, 'Resident created successfully', 201);
  } catch (err) {
    if (err.code === 'P2002') return error(res, 'NIK already registered', 409, 'CONFLICT');
    next(err);
  }
};

const updateResident = async (req, res, next) => {
  try {
    const resident = await regionsService.updateResident(req.params.id, req.body);
    return success(res, resident, 'Resident updated successfully');
  } catch (err) {
    if (err.code === 'P2025') return error(res, 'Resident not found', 404, 'NOT_FOUND');
    next(err);
  }
};

module.exports = { getRegions, createRegion, getResidents, createResident, updateResident };
