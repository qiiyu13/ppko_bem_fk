const { PrismaClient } = require('@prisma/client');
const { calculateIrd } = require('../../utils/ird');

const prisma = new PrismaClient();

const createScreening = async (data, userId) => {
  // Fetch profile to get gender/height/weight for IRD
  const profile = await prisma.familyProfile.findUnique({
    where: { id: data.profileId },
  });
  if (!profile) throw Object.assign(new Error('Profile not found'), { statusCode: 404 });

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

  return prisma.medicalScreening.create({
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
};

const getScreenings = async (profileId) => {
  return prisma.medicalScreening.findMany({
    where: profileId ? { profileId } : {},
    orderBy: { screeningAt: 'desc' },
    include: {
      profile: { select: { name: true, nik: true, gender: true } },
      screener: { select: { name: true } },
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
