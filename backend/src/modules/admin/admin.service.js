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

  // Get all matching users to compute their latest screenings and totals
  const allFilteredUsers = await prisma.user.findMany({
    where: userFilter,
    select: {
      id: true,
      familyProfiles: {
        select: {
          screenings: {
            orderBy: { screeningAt: 'desc' },
            take: 1,
            select: { irdCategory: true, screeningAt: true },
          }
        }
      }
    }
  });

  let totalHighRisk = 0;
  let totalAttention = 0;
  let totalNormal = 0;
  const matchedUserIds = [];

  for (const user of allFilteredUsers) {
    let hasMatchingProfile = false;

    for (const profile of user.familyProfiles) {
      const latestProfileScreening = profile.screenings[0];
      if (latestProfileScreening) {
        const cat = latestProfileScreening.irdCategory;
        if (cat === 'high') totalHighRisk++;
        else if (cat === 'attention') totalAttention++;
        else if (cat === 'normal') totalNormal++;

        if (cat === irdCategory) {
          hasMatchingProfile = true;
        }
      }
    }

    if (!irdCategory || hasMatchingProfile) {
      matchedUserIds.push(user.id);
    }
  }

  const where = { ...userFilter, id: { in: matchedUserIds } };

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
