const { broadcastToUsers, broadcastToAll, events } = require('../../websocket');
const { calculateIrd } = require('../../utils/ird');
const { parsePagination } = require('../../utils/pagination');
const { createAndSend } = require('../notifications/notifications.service');

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

  const bloodSugar = data.bloodSugar != null ? parseFloat(data.bloodSugar) : 0;
  const cholesterol = data.cholesterol != null ? parseFloat(data.cholesterol) : 0;
  const uricAcid = data.uricAcid != null ? parseFloat(data.uricAcid) : 0;

  const irdResult = calculateIrd({
    bloodSugar,
    systolic: parseInt(data.systolic),
    diastolic: parseInt(data.diastolic),
    cholesterol,
    uricAcid,
    height: parseFloat(height),
    weight: parseFloat(weight),
    gender,
  });

  const screeningAt = data.screeningAt ? new Date(data.screeningAt) : new Date();

  const result = await prisma.$transaction(async (tx) => {
    const screening = await tx.medicalScreening.create({
      data: {
        profileId: data.profileId,
        screenedBy: userId,
        systolic: parseInt(data.systolic),
        diastolic: parseInt(data.diastolic),
        bloodSugar: data.bloodSugar != null ? parseFloat(data.bloodSugar) : null,
        cholesterol: data.cholesterol != null ? parseFloat(data.cholesterol) : null,
        uricAcid: data.uricAcid != null ? parseFloat(data.uricAcid) : null,
        height: parseFloat(height),
        weight: parseFloat(weight),
        irdScore: irdResult.irdScore,
        irdCategory: irdResult.irdCategory,
        notes: data.notes || null,
        screeningAt,
      },
    });

    const metricRows = [];
    if (data.systolic != null && data.diastolic != null) {
      metricRows.push({
        profileId: data.profileId,
        type: 'blood_pressure',
        value: parseInt(data.systolic),
        secondaryValue: parseInt(data.diastolic),
        unit: 'mmHg',
        recordedAt: screeningAt,
      });
    }
    if (data.bloodSugar != null) {
      metricRows.push({
        profileId: data.profileId,
        type: 'blood_sugar',
        value: parseFloat(data.bloodSugar),
        unit: 'mg/dL',
        recordedAt: screeningAt,
      });
    }
    if (data.cholesterol != null) {
      metricRows.push({
        profileId: data.profileId,
        type: 'cholesterol',
        value: parseFloat(data.cholesterol),
        unit: 'mg/dL',
        recordedAt: screeningAt,
      });
    }
    if (data.uricAcid != null) {
      metricRows.push({
        profileId: data.profileId,
        type: 'uric_acid',
        value: parseFloat(data.uricAcid),
        unit: 'mg/dL',
        recordedAt: screeningAt,
      });
    }

    if (metricRows.length > 0) {
      await tx.healthMetric.createMany({ data: metricRows });
    }

    return screening;
  });

  try {
    broadcastToUsers([profile.userId], events.DATA_UPDATE, { type: 'screenings', action: 'create', profileId: result.profileId });
    broadcastToUsers([profile.userId], events.DATA_UPDATE, { type: 'metrics', action: 'create', profileId: result.profileId });
  } catch (e) {
    console.error('WebSocket broadcast failed:', e.message);
  }
  try {
    const categoryLabel = result.irdCategory === 'RENDAH' ? 'Risiko Rendah'
      : result.irdCategory === 'SEDANG' ? 'Risiko Sedang'
      : result.irdCategory === 'TINGGI' ? 'Risiko Tinggi'
      : result.irdCategory;
    await createAndSend(profile.userId, {
      title: 'Hasil Skrining Tersedia',
      body: `Skrining kesehatan ${profile.name} selesai. Kategori IRD: ${categoryLabel}.`,
      type: 'screeningResult',
      data: { screeningId: result.id, profileId: result.profileId },
    });
  } catch (e) { console.error('Notification send failed:', e.message); }
  return result;
};

const getScreenings = async (profileId, query) => {
  const { page, limit, skip } = parsePagination(query);
  const where = profileId ? { profileId } : {};
  const [data, total] = await Promise.all([
    prisma.medicalScreening.findMany({
      where, skip, take: limit,
      orderBy: { screeningAt: 'desc' },
      include: {
        profile: { select: { name: true, nik: true, gender: true } },
        screener: { select: { responsibleName: true } },
      },
    }),
    prisma.medicalScreening.count({ where }),
  ]);
  return { data, total, page, limit };
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
