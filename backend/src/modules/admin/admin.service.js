const prisma = require('../../utils/prisma');

const getPatients = async ({ search, irdCategory, page = 1, limit = 10, regionId }) => {
  const skip = (parseInt(page) - 1) * parseInt(limit);
  const take = parseInt(limit);

  const userFilter = { role: 'PATIENT' };

  if (regionId && regionId !== '') {
    userFilter.region = {
      OR: [
        { id: regionId },
        { parentId: regionId },
        { parent: { parentId: regionId } }
      ]
    };
  }

  if (search) {
    userFilter.OR = [
      { responsibleName: { contains: search, mode: 'insensitive' } },
      { kkNumber: { contains: search, mode: 'insensitive' } },
      { familyProfiles: { some: { name: { contains: search, mode: 'insensitive' } } } },
    ];
  }

  // 1. Get all screenings matching the userFilter, sorted by date desc to find the latest for each profile
  const allScreenings = await prisma.medicalScreening.findMany({
    where: {
      profile: {
        user: userFilter
      }
    },
    orderBy: {
      screeningAt: 'desc'
    },
    select: {
      profileId: true,
      irdCategory: true
    }
  });

  // 2. Identify the latest screening category per profile
  const latestScreeningsMap = new Map();
  for (const s of allScreenings) {
    if (!latestScreeningsMap.has(s.profileId)) {
      latestScreeningsMap.set(s.profileId, s.irdCategory);
    }
  }

  // 3. Compute risk stats
  let totalHighRisk = 0;
  let totalAttention = 0;
  let totalNormal = 0;

  for (const cat of latestScreeningsMap.values()) {
    if (cat === 'high') totalHighRisk++;
    else if (cat === 'attention') totalAttention++;
    else if (cat === 'normal') totalNormal++;
  }

  // 4. Handle filtering by irdCategory
  let where = userFilter;
  if (irdCategory) {
    const matchedProfileIds = [];
    for (const [profileId, cat] of latestScreeningsMap.entries()) {
      if (cat === irdCategory) {
        matchedProfileIds.push(profileId);
      }
    }

    // Query userIds corresponding to matched profiles
    const profiles = await prisma.familyProfile.findMany({
      where: { id: { in: matchedProfileIds } },
      select: { userId: true }
    });

    const matchedUserIds = Array.from(new Set(profiles.map(p => p.userId)));
    where = { ...userFilter, id: { in: matchedUserIds } };
  }

  // 5. Paginated fetch
  const [users, total] = await Promise.all([
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
