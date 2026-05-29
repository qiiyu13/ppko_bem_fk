const appointmentsService = require('./appointments.service');
const { success, error, paginated } = require('../../utils/response');

const getAppointments = async (req, res, next) => {
  try {
    const { profileId } = req.query;
    const result = await appointmentsService.getAppointments(req.user.id, profileId, req.query);
    if (result && result.data !== undefined) {
      return paginated(res, result.data, result.total, result.page, result.limit);
    }
    return success(res, result);
  } catch (err) {
    next(err);
  }
};

const getAppointmentById = async (req, res, next) => {
  try {
    const appointment = await appointmentsService.getAppointmentById(req.params.id, req.user.id);
    return success(res, appointment);
  } catch (err) {
    if (err.message === 'Appointment not found') return error(res, err.message, 404, 'NOT_FOUND');
    next(err);
  }
};

const createAppointment = async (req, res, next) => {
  try {
    const appointment = await appointmentsService.createAppointment(req.body, req.user.id);
    return success(res, appointment, 'Appointment created successfully', 201);
  } catch (err) {
    next(err);
  }
};

const updateAppointment = async (req, res, next) => {
  try {
    const appointment = await appointmentsService.updateAppointment(req.params.id, req.body, req.user.id);
    return success(res, appointment, 'Appointment updated successfully');
  } catch (err) {
    if (err.message === 'Appointment not found') return error(res, err.message, 404, 'NOT_FOUND');
    next(err);
  }
};

const deleteAppointment = async (req, res, next) => {
  try {
    const result = await appointmentsService.deleteAppointment(req.params.id, req.user.id);
    return success(res, result);
  } catch (err) {
    if (err.message === 'Appointment not found') return error(res, err.message, 404, 'NOT_FOUND');
    next(err);
  }
};

module.exports = { getAppointments, getAppointmentById, createAppointment, updateAppointment, deleteAppointment };
