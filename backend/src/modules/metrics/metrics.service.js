const prisma = require('../../utils/prisma');

const getMetrics = async (profileId, userId) => {
  // Verify profile belongs to user
  const profile = await prisma.familyProfile.findFirst({
    where: { id: profileId, userId },
  });
  if (!profile) throw Object.assign(new Error('Profile not found'), { statusCode: 404 });

  return prisma.healthMetric.findMany({
    where: { profileId },
    orderBy: { recordedAt: 'desc' },
  });
};

const createMetric = async (data) => {
  return prisma.healthMetric.create({
    data: {
      profileId: data.profileId,
      type: data.type,
      value: parseFloat(data.value),
      secondaryValue: data.secondaryValue ? parseFloat(data.secondaryValue) : null,
      unit: data.unit,
      notes: data.notes || null,
      recordedAt: data.recordedAt ? new Date(data.recordedAt) : new Date(),
    },
  });
};

const getHistory = async (profileId, type, userId) => {
  // Verify profile belongs to user
  const profile = await prisma.familyProfile.findFirst({
    where: { id: profileId, userId },
  });
  if (!profile) throw Object.assign(new Error('Profile not found'), { statusCode: 404 });

  return prisma.healthMetric.findMany({
    where: { profileId, type },
    orderBy: { recordedAt: 'asc' },
  });
};

const getLatest = async (profileId, userId) => {
  // Verify profile belongs to user
  const profile = await prisma.familyProfile.findFirst({
    where: { id: profileId, userId },
  });
  if (!profile) throw Object.assign(new Error('Profile not found'), { statusCode: 404 });

  const types = await prisma.healthMetric.findMany({
    where: { profileId },
    distinct: ['type'],
    orderBy: { recordedAt: 'desc' },
  });

  return types;
};

module.exports = { getMetrics, createMetric, getHistory, getLatest };
