const { broadcastToUsers, broadcastToAll, events } = require('../../websocket');
const { calculateIrd } = require('../../utils/ird');

const prisma = require('../../utils/prisma');

const createScreening = async (data, userId) => {
  const profile = await prisma.familyProfile.findUnique({
    where: { id: data.profileId },
  });
  if (!profile) throw Object.assign(new Error('Profile not found'), { statusCode: 404 });

  const screener = await prisma.user.findUnique({ where: { id: userId }, select: { role: true } });
  if (profile.userId !== userId && screener.role === 'PATIENT') {
    throw Object.assign(new Error('Not authorized to screen this profile'), { statusCode: 403 });
  }

  const height = data.height || profile.height;
  const weight = data.weight || profile.weight;
  const gender = data.gender || profile.gender;

  if (!height || !weight || !gender) {
    throw Object.assign(new Error('Height, weight, and gender are required for IRD calculation'), { statusCode: 400 });
  }

  const irdResult = calculateIrd({
    bloodSugar: parseFloat(data.bloodSugar),
    systolic: parseInt(data.systolic),
    diastolic: parseInt(data.diastolic),
    cholesterol: parseFloat(data.cholesterol),
    uricAcid: parseFloat(data.uricAcid),
    height: parseFloat(height),
    weight: parseFloat(weight),
    gender,
  });

  const result = await prisma.medicalScreening.create({
    data: {
      profileId: data.profileId,
      screenedBy: userId,
      systolic: parseInt(data.systolic),
      diastolic: parseInt(data.diastolic),
      bloodSugar: parseFloat(data.bloodSugar),
      cholesterol: parseFloat(data.cholesterol),
      uricAcid: parseFloat(data.uricAcid),
      height: parseFloat(height),
      weight: parseFloat(weight),
      irdScore: irdResult.irdScore,
      irdCategory: irdResult.irdCategory,
      notes: data.notes || null,
      screeningAt: data.screeningAt ? new Date(data.screeningAt) : new Date(),
    },
  });
  try { broadcastToUsers([profile.userId], events.DATA_UPDATE, { type: 'screenings', action: 'create', profileId: result.profileId }); } catch (e) { console.error('WebSocket broadcast failed:', e.message); }
  return result;
};

const getScreenings = async (profileId) => {
  return prisma.medicalScreening.findMany({
    where: profileId ? { profileId } : {},
    orderBy: { screeningAt: 'desc' },
    include: {
      profile: { select: { name: true, nik: true, gender: true } },
      screener: { select: { responsibleName: true } },
    },
  });
};

const getStats = async () => {
  const all = await prisma.medicalScreening.groupBy({
    by: ['irdCategory'],
    _count: { irdCategory: true },
  });

  const total = await prisma.medicalScreening.count();

  return {
    total,
    byCategory: all.reduce((acc, item) => {
      acc[item.irdCategory] = item._count.irdCategory;
      return acc;
    }, {}),
  };
};

module.exports = { createScreening, getScreenings, getStats };
