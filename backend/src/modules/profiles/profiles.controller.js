const profilesService = require('./profiles.service');
const { success, error } = require('../../utils/response');

const getProfiles = async (req, res, next) => {
  try {
    const profiles = await profilesService.getProfiles(req.user.id);
    return success(res, profiles);
  } catch (err) {
    next(err);
  }
};

const getProfile = async (req, res, next) => {
  try {
    const profile = await profilesService.getProfile(req.params.id, req.user.id);
    return success(res, profile);
  } catch (err) {
    if (err.message === 'Profile not found') return error(res, err.message, 404, 'NOT_FOUND');
    next(err);
  }
};

const createProfile = async (req, res, next) => {
  try {
    const data = { ...req.body };
    if (req.file) data.avatarPath = `/uploads/avatars/${req.file.filename}`;
    const profile = await profilesService.createProfile(data, req.user.id);
    return success(res, profile, 'Profile created successfully', 201);
  } catch (err) {
    next(err);
  }
};

const updateProfile = async (req, res, next) => {
  try {
    const data = { ...req.body };
    if (req.file) data.avatarPath = `/uploads/avatars/${req.file.filename}`;
    const profile = await profilesService.updateProfile(req.params.id, data, req.user.id);
    return success(res, profile, 'Profile updated successfully');
  } catch (err) {
    if (err.message === 'Profile not found') return error(res, err.message, 404, 'NOT_FOUND');
    next(err);
  }
};

const deleteProfile = async (req, res, next) => {
  try {
    const result = await profilesService.deleteProfile(req.params.id, req.user.id);
    return success(res, result);
  } catch (err) {
    if (err.message === 'Profile not found') return error(res, err.message, 404, 'NOT_FOUND');
    next(err);
  }
};

module.exports = { getProfiles, getProfile, createProfile, updateProfile, deleteProfile };
