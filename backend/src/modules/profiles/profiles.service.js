const { broadcastToUsers, broadcastToAll, events } = require('../../websocket');

const prisma = require('../../utils/prisma');

const getProfiles = async (userId) => {
  return prisma.familyProfile.findMany({
    where: { userId },
    orderBy: { createdAt: 'asc' },
  });
};

const getProfile = async (id, userId) => {
  const profile = await prisma.familyProfile.findFirst({
    where: { id, userId },
  });
  if (!profile) throw Object.assign(new Error('Profile not found'), { statusCode: 404 });
  return profile;
};

const createProfile = async (data, userId) => {
  const result = await prisma.familyProfile.create({
    data: {
      userId,
      name: data.name,
      nik: data.nik,
      gender: data.gender,
      birthDate: new Date(data.birthDate),
      height: data.height ? parseFloat(data.height) : null,
      weight: data.weight ? parseFloat(data.weight) : null,
      bloodType: data.bloodType || null,
      phone: data.phone || null,
    },
  });
  try { broadcastToUsers([userId], events.DATA_UPDATE, { type: 'profiles', action: 'create', id: result.id }); } catch (e) { console.error('WebSocket broadcast failed:', e.message); }
  return result;
};

const updateProfile = async (id, data, userId) => {
  await getProfile(id, userId); // verify ownership

  const updateData = {};
  if (data.name !== undefined) updateData.name = data.name;
  if (data.nik !== undefined) updateData.nik = data.nik;
  if (data.gender !== undefined) updateData.gender = data.gender;
  if (data.birthDate !== undefined) updateData.birthDate = new Date(data.birthDate);
  if (data.height !== undefined) updateData.height = data.height ? parseFloat(data.height) : null;
  if (data.weight !== undefined) updateData.weight = data.weight ? parseFloat(data.weight) : null;
  if (data.bloodType !== undefined) updateData.bloodType = data.bloodType || null;
  if (data.phone !== undefined) updateData.phone = data.phone || null;

  const result = await prisma.familyProfile.update({
    where: { id },
    data: updateData,
  });
  try { broadcastToUsers([userId], events.DATA_UPDATE, { type: 'profiles', action: 'update', id }); } catch (e) { console.error('WebSocket broadcast failed:', e.message); }
  return result;
};

const deleteProfile = async (id, userId) => {
  await getProfile(id, userId); // verify ownership

  await prisma.$transaction([
    prisma.healthMetric.deleteMany({ where: { profileId: id } }),
    prisma.medicalScreening.deleteMany({ where: { profileId: id } }),
    prisma.familyProfile.delete({ where: { id } }),
  ]);

  try { broadcastToUsers([userId], events.DATA_UPDATE, { type: 'profiles', action: 'delete', id }); } catch (e) { console.error('WebSocket broadcast failed:', e.message); }
  return { message: 'Profile deleted successfully' };
};

module.exports = { getProfiles, getProfile, createProfile, updateProfile, deleteProfile };
