const { PrismaClient } = require('@prisma/client');
const { broadcastToUsers, broadcastToAll, events } = require('../../websocket');

const prisma = new PrismaClient();

const getAppointments = async (userId, profileId) => {
  const where = { userId };
  if (profileId) where.profileId = profileId;

  return prisma.appointment.findMany({
    where,
    orderBy: { date: 'asc' },
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
  try { broadcastToUsers([userId], events.DATA_UPDATE, { type: 'appointments', action: 'create', id: result.id }); } catch (e) {}
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
  try { broadcastToUsers([userId], events.DATA_UPDATE, { type: 'appointments', action: 'update', id }); } catch (e) {}
  return result;
};

const deleteAppointment = async (id, userId) => {
  const appointment = await prisma.appointment.findFirst({
    where: { id, userId },
  });
  if (!appointment) throw Object.assign(new Error('Appointment not found'), { statusCode: 404 });

  await prisma.appointment.delete({ where: { id } });
  try { broadcastToUsers([userId], events.DATA_UPDATE, { type: 'appointments', action: 'delete', id }); } catch (e) {}
  return { message: 'Appointment deleted successfully' };
};

module.exports = { getAppointments, createAppointment, updateAppointment, deleteAppointment };
