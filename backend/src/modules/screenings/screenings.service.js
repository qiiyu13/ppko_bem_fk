const { broadcastToUsers, broadcastToAll, events } = require('../../websocket');
const { calculateIrd } = require('../../utils/ird');
const { parsePagination } = require('../../utils/pagination');
const { parseClientDate } = require('../../utils/clientDate');
const { regionScopeFilter } = require('../../utils/regionScope');
const { createAndSend } = require('../notifications/notifications.service');
const { getAccessibleProfile } = require('../../utils/profileAccess');

const prisma = require('../../utils/prisma');

const createScreening = async (data, userId, role) => {
  // PATIENT role must own or be linked to the profile; ADMIN/SUPERADMIN can
  // screen any profile regardless of ownership.
  const profile = role === 'PATIENT'
    ? await getAccessibleProfile(data.profileId, userId)
    : await prisma.familyProfile.findFirst({ where: { id: data.profileId, mergedIntoId: null } });
  if (!profile) throw Object.assign(new Error('Profile not found'), { statusCode: 404 });

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

  const screeningAt = data.screeningAt ? parseClientDate(data.screeningAt) : new Date();

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
    // Same vocabulary as the app screens (Normal/Perhatian/Tinggi) so the
    // notification, patient report, and admin report all say the same thing.
    const categoryLabel = result.irdCategory === 'high' ? 'Tinggi'
      : result.irdCategory === 'attention' ? 'Perhatian'
      : result.irdCategory === 'normal' ? 'Normal'
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

const getScreenings = async (profileId, query, requester) => {
  const { page, limit, skip } = parsePagination(query);
  const where = profileId ? { profileId } : {};
  // Patients may only read screenings of their own family profiles, regardless
  // of which profileId they pass (or none). Admins are confined to their region
  // subtree like the rest of the admin module; superadmins see everything.
  if (requester.role === 'PATIENT') {
    where.profile = { OR: [{ userId: requester.id }, { links: { some: { userId: requester.id } } }] };
  } else if (requester.role === 'ADMIN') {
    const me = await prisma.user.findUnique({ where: { id: requester.id }, select: { regionId: true } });
    // Region-less admin matches nothing, mirroring admin.service's 404 stance.
    where.profile = { user: regionScopeFilter(me?.regionId ?? '__none__') };
  }
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

const getStats = async (requester = {}) => {
  let regionId = null;
  if (requester.role === 'ADMIN') {
    const me = await prisma.user.findUnique({ where: { id: requester.id }, select: { regionId: true } });
    regionId = me?.regionId;
    if (!regionId) return { total: 0, categories: { high: 0, attention: 0, normal: 0 } };
  }

  // Latest screening per profile; for ADMIN, only profiles whose owner sits in
  // the admin's region subtree (region itself, children, grandchildren).
  const stats = regionId
    ? await prisma.$queryRaw`
        SELECT ird_category as "irdCategory", COUNT(*)::int as "count"
        FROM (
          SELECT DISTINCT ON (ms.profile_id) ms.ird_category
          FROM medical_screenings ms
          JOIN family_profiles fp ON fp.id = ms.profile_id
          JOIN users u ON u.id = fp.user_id
          JOIN regions r ON r.id = u.region_id
          LEFT JOIN regions p ON p.id = r.parent_id
          WHERE r.id = ${regionId} OR r.parent_id = ${regionId} OR p.parent_id = ${regionId}
          ORDER BY ms.profile_id, ms.screening_at DESC
        ) t
        GROUP BY ird_category
      `
    : await prisma.$queryRaw`
        SELECT ird_category as "irdCategory", COUNT(*)::int as "count"
        FROM (
          SELECT DISTINCT ON (profile_id) ird_category
          FROM medical_screenings
          ORDER BY profile_id, screening_at DESC
        ) t
        GROUP BY ird_category
      `;

  const categories = { high: 0, attention: 0, normal: 0 };
  let total = 0;
  for (const s of stats) {
    const cat = s.irdCategory;
    if (cat && categories[cat] !== undefined) {
      categories[cat] = Number(s.count);
      total += Number(s.count);
    }
  }

  return {
    total,
    categories,
  };
};

// Report listing for admins/superadmins: filter by screener + date range.
// Returns the filtered set (unpaginated) so the client can export it, but
// hard-capped to protect the server from unbounded result sets / OOM. The
// caller is told when the cap kicked in so exports can say so.
const REPORT_MAX_ROWS = 5000;
const getScreeningReport = async ({ screenedBy, from, to }) => {
  const where = {};
  if (screenedBy) where.screenedBy = screenedBy;
  if (from || to) {
    where.screeningAt = {};
    if (from) where.screeningAt.gte = parseClientDate(from);
    if (to) where.screeningAt.lte = parseClientDate(to);
  }
  const rows = await prisma.medicalScreening.findMany({
    where,
    orderBy: { screeningAt: 'desc' },
    take: REPORT_MAX_ROWS + 1,
    include: {
      profile: { select: { name: true, nik: true, gender: true } },
      screener: { select: { id: true, responsibleName: true } },
    },
  });
  const truncated = rows.length > REPORT_MAX_ROWS;
  return { rows: truncated ? rows.slice(0, REPORT_MAX_ROWS) : rows, truncated };
};

module.exports = { createScreening, getScreenings, getStats, getScreeningReport, REPORT_MAX_ROWS };
