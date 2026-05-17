const prisma = require('../../utils/prisma');

const getPatients = async ({ search, irdCategory, page = 1, limit = 10 }) => {
  const skip = (parseInt(page) - 1) * parseInt(limit);
  const take = parseInt(limit);

  const where = { role: 'PATIENT' };

  if (search) {
    where.OR = [
      { responsibleName: { contains: search, mode: 'insensitive' } },
      { kkNumber: { contains: search, mode: 'insensitive' } },
      { familyProfiles: { some: { name: { contains: search, mode: 'insensitive' } } } },
    ];
  }

  // If filtering by IRD category, we need to find patients whose latest screening matches
  let patientIds = null;
  if (irdCategory) {
    const screenings = await prisma.medicalScreening.findMany({
      where: { irdCategory },
      orderBy: { screeningAt: 'desc' },
      distinct: ['profileId'],
      select: { profileId: true },
    });

    const profileIds = screenings.map((s) => s.profileId);
    const profiles = await prisma.familyProfile.findMany({
      where: { id: { in: profileIds } },
      select: { userId: true },
    });

    patientIds = [...new Set(profiles.map((p) => p.userId))];
    where.id = { in: patientIds };
  }

  // Get latest screening per profile to compute per-category totals (global, ignoring pagination)
  const latestScreenings = await prisma.medicalScreening.findMany({
    orderBy: { screeningAt: 'desc' },
    distinct: ['profileId'],
    select: { profileId: true, irdCategory: true },
  });
  const profilesByCategory = { high: [], attention: [], normal: [] };
  for (const s of latestScreenings) {
    if (s.irdCategory && profilesByCategory[s.irdCategory]) {
      profilesByCategory[s.irdCategory].push(s.profileId);
    }
  }
  const countCategory = async (profileIds) => {
    if (!profileIds.length) return 0;
    const rows = await prisma.familyProfile.findMany({
      where: { id: { in: profileIds } },
      select: { userId: true },
      distinct: ['userId'],
    });
    return rows.length;
  };

  const [users, total, totalHighRisk, totalAttention, totalNormal] = await Promise.all([
    prisma.user.findMany({
      where,
      skip,
      take,
      orderBy: { createdAt: 'desc' },
      select: {
        id: true,
        kkNumber: true,
        responsibleName: true,
        phone: true,
        createdAt: true,
        familyProfiles: {
          select: {
            id: true,
            name: true,
            screenings: {
              orderBy: { screeningAt: 'desc' },
              take: 1,
              select: { irdScore: true, irdCategory: true, screeningAt: true },
            },
          },
        },
      },
    }),
    prisma.user.count({ where }),
    countCategory(profilesByCategory.high),
    countCategory(profilesByCategory.attention),
    countCategory(profilesByCategory.normal),
  ]);

  // Flatten latest IRD per patient
  const data = users.map((user) => {
    const allScreenings = user.familyProfiles.flatMap((p) => p.screenings);
    const latest = allScreenings.sort((a, b) => new Date(b.screeningAt) - new Date(a.screeningAt))[0];

    return {
      id: user.id,
      name: user.responsibleName,
      nik: user.kkNumber,
      phone: user.phone,
      createdAt: user.createdAt,
      latestIrd: latest || null,
    };
  });

  return { data, total, totalHighRisk, totalAttention, totalNormal, page: parseInt(page), limit: take };
};

const getPatientDetail = async (id) => {
  const user = await prisma.user.findFirst({
    where: { id, role: 'PATIENT' },
    select: {
      id: true,
      kkNumber: true,
      responsibleName: true,
      phone: true,
      createdAt: true,
      familyProfiles: {
        select: {
          id: true,
          name: true,
          nik: true,
          gender: true,
          birthDate: true,
          height: true,
          weight: true,
          bloodType: true,
          phone: true,
          metrics: {
            orderBy: { recordedAt: 'desc' },
            take: 50,
          },
          screenings: {
            orderBy: { screeningAt: 'desc' },
            take: 20,
            include: { screener: { select: { responsibleName: true } } },
          },
        },
      },
      appointments: {
        orderBy: { date: 'desc' },
        take: 20,
      },
    },
  });

  if (!user) throw Object.assign(new Error('Patient not found'), { statusCode: 404 });
  return user;
};

module.exports = { getPatients, getPatientDetail };
