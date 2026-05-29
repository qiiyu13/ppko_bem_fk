const { Prisma } = require('@prisma/client');
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

  // 1. Resolve profiles belonging to users matching the filter (bounded by profile
  //    count, not screening count). Region/search logic stays in Prisma.
  const matchingProfiles = await prisma.familyProfile.findMany({
    where: { user: userFilter },
    select: { id: true },
  });
  const matchingProfileIds = matchingProfiles.map((p) => p.id);

  // 2. Latest screening category per profile via DISTINCT ON, served by the
  //    (profile_id, screening_at DESC) index — one indexed row per profile
  //    instead of scanning every screening row into memory.
  const latestScreeningsMap = new Map();
  if (matchingProfileIds.length > 0) {
    const latest = await prisma.$queryRaw`
      SELECT DISTINCT ON (profile_id) profile_id AS "profileId", ird_category AS "irdCategory"
      FROM medical_screenings
      WHERE profile_id IN (${Prisma.join(matchingProfileIds)})
      ORDER BY profile_id, screening_at DESC
    `;
    for (const s of latest) {
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
        avatarPath: true,
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
      avatarPath: user.avatarPath || null,
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
          avatarPath: true,
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
