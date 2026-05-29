const { broadcastToUsers, broadcastToAll, events } = require('../../websocket');
const { createAndSend, createAndSendToAllPatients } = require('../notifications/notifications.service');

const prisma = require('../../utils/prisma');
const { parsePagination } = require('../../utils/pagination');

const getAppointmentById = async (id, userId) => {
  const appointment = await prisma.appointment.findFirst({
    where: {
      id,
      OR: [
        { userId },
        { type: 'JADWAL' },
      ],
    },
  });
  if (!appointment) throw Object.assign(new Error('Appointment not found'), { statusCode: 404 });
  return appointment;
};

const getAppointments = async (userId, profileId, query = {}) => {
  const personalWhere = { userId };
  if (profileId) personalWhere.profileId = profileId;

  const where = {
    OR: [
      personalWhere,
      { type: 'JADWAL' },
    ],
  };

  if (query.page !== undefined || query.limit !== undefined) {
    const { page, limit, skip } = parsePagination(query);
    const [data, total] = await Promise.all([
      prisma.appointment.findMany({
        where,
        skip,
        take: limit,
        orderBy: { date: 'asc' },
      }),
      prisma.appointment.count({ where }),
    ]);
    return { data, total, page, limit };
  }

  return prisma.appointment.findMany({
    where,
    orderBy: { date: 'asc' },
    take: 200,
  });
};

const createAppointment = async (data, userId) => {
  const result = await prisma.appointment.create({
    data: {
      userId,
      profileId: data.profileId || null,
      title: data.title,
      date: new Date(data.date),
      location: data.location || null,
      notes: data.notes || null,
      type: data.type || 'GENERAL',
    },
  });

  const isJadwal = result.type === 'JADWAL';
  const dateStr = new Date(result.date).toLocaleDateString('id-ID', { day: 'numeric', month: 'long', year: 'numeric' });
  const notifBody = `${result.title} pada ${dateStr}${result.location ? ' di ' + result.location : ''}`;

  try {
    if (isJadwal) {
      broadcastToAll(events.DATA_UPDATE, { type: 'appointments', action: 'create', id: result.id });
    } else {
      broadcastToUsers([userId], events.DATA_UPDATE, { type: 'appointments', action: 'create', id: result.id });
    }
  } catch (e) { console.error('WebSocket broadcast failed:', e.message); }

  try {
    if (isJadwal) {
      await createAndSendToAllPatients({
        title: 'Jadwal Skrining Baru',
        body: notifBody,
        type: 'appointment',
        data: { appointmentId: result.id },
      });
    } else {
      await createAndSend(userId, {
        title: 'Jadwal Baru Ditambahkan',
        body: notifBody,
        type: 'appointment',
        data: { appointmentId: result.id },
      });
    }
  } catch (e) { console.error('Notification send failed:', e.message); }
  return result;
};

const updateAppointment = async (id, data, userId) => {
  const appointment = await prisma.appointment.findFirst({
    where: { id, userId },
  });
  if (!appointment) throw Object.assign(new Error('Appointment not found'), { statusCode: 404 });

  const updateData = {};
  if (data.title !== undefined) updateData.title = data.title;
  if (data.date !== undefined) updateData.date = new Date(data.date);
  if (data.location !== undefined) updateData.location = data.location || null;
  if (data.notes !== undefined) updateData.notes = data.notes || null;
  if (data.type !== undefined) updateData.type = data.type;

  const result = await prisma.appointment.update({
    where: { id },
    data: updateData,
  });
  try {
    if (result.type === 'JADWAL') {
      broadcastToAll(events.DATA_UPDATE, { type: 'appointments', action: 'update', id });
    } else {
      broadcastToUsers([userId], events.DATA_UPDATE, { type: 'appointments', action: 'update', id });
    }
  } catch (e) { console.error('WebSocket broadcast failed:', e.message); }
  return result;
};

const deleteAppointment = async (id, userId) => {
  const appointment = await prisma.appointment.findFirst({
    where: { id, userId },
  });
  if (!appointment) throw Object.assign(new Error('Appointment not found'), { statusCode: 404 });

  await prisma.appointment.delete({ where: { id } });
  try {
    if (appointment.type === 'JADWAL') {
      broadcastToAll(events.DATA_UPDATE, { type: 'appointments', action: 'delete', id });
    } else {
      broadcastToUsers([userId], events.DATA_UPDATE, { type: 'appointments', action: 'delete', id });
    }
  } catch (e) { console.error('WebSocket broadcast failed:', e.message); }
  return { message: 'Appointment deleted successfully' };
};

module.exports = { getAppointmentById, getAppointments, createAppointment, updateAppointment, deleteAppointment };
