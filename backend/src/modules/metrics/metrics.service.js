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
  const profile = await prisma.familyProfile.findFirst({
    where: { id: profileId, userId },
  });
  if (!profile) throw Object.assign(new Error('Profile not found'), { statusCode: 404 });

  const records = await prisma.healthMetric.findMany({
    where: { profileId, type },
    orderBy: { recordedAt: 'asc' },
  });

  return records.map((r) => ({
    date: r.recordedAt,
    value: r.value,
    secondaryValue: r.secondaryValue,
    notes: r.notes,
  }));
};

const getLatest = async (profileId, userId) => {
  const profile = await prisma.familyProfile.findFirst({
    where: { id: profileId, userId },
  });
  if (!profile) throw Object.assign(new Error('Profile not found'), { statusCode: 404 });

  const metricTypes = ['blood_pressure', 'cholesterol', 'blood_sugar', 'uric_acid'];

  const results = await Promise.all(
    metricTypes.map(async (type) => {
      const latest = await prisma.healthMetric.findFirst({
        where: { profileId, type },
        orderBy: { recordedAt: 'desc' },
      });
      if (!latest) return null;

      const recent = await prisma.healthMetric.findMany({
        where: { profileId, type },
        orderBy: { recordedAt: 'desc' },
        take: 7,
        select: { value: true },
      });

      return {
        type: latest.type,
        value: latest.value,
        secondaryValue: latest.secondaryValue,
        unit: latest.unit,
        notes: latest.notes,
        lastUpdated: latest.recordedAt,
        recentValues: recent.map((r) => r.value).reverse(),
      };
    }),
  );

  return results.filter(Boolean);
};

module.exports = { getMetrics, createMetric, getHistory, getLatest };
