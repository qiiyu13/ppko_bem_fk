const prisma = require('../../utils/prisma');
const { parsePagination } = require('../../utils/pagination');

const getMetrics = async (profileId, userId, query) => {
  // Verify profile belongs to user
  const profile = await prisma.familyProfile.findFirst({
    where: { id: profileId, userId },
  });
  if (!profile) throw Object.assign(new Error('Profile not found'), { statusCode: 404 });

  const { page, limit, skip } = parsePagination(query);
  const where = { profileId };
  const [data, total] = await Promise.all([
    prisma.healthMetric.findMany({ where, skip, take: limit, orderBy: { recordedAt: 'desc' } }),
    prisma.healthMetric.count({ where }),
  ]);
  return { data, total, page, limit };
};

const createMetric = async (data, userId) => {
  // Verify profile belongs to user
  const profile = await prisma.familyProfile.findFirst({
    where: { id: data.profileId, userId },
  });
  if (!profile) throw Object.assign(new Error('Profile not found'), { statusCode: 404 });

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
