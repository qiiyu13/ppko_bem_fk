const { Prisma } = require('@prisma/client');
const prisma = require('../../utils/prisma');
const { regionScopeFilter } = require('../../utils/regionScope');

// An ADMIN sees only their own region; the client-supplied regionId is ignored.
// A region-less admin is misconfigured and resolves to a sentinel that matches
// no region (fail closed). SUPERADMIN keeps the client-supplied regionId.
const resolveScopedRegionId = async (actor, clientRegionId) => {
  if (actor?.role !== 'ADMIN') return clientRegionId;
  const me = await prisma.user.findUnique({ where: { id: actor.id }, select: { regionId: true } });
  return me?.regionId || '__no_region__';
};

const getPatients = async ({ search, irdCategory, page = 1, limit = 10, regionId }, actor = {}) => {
  const skip = (parseInt(page) - 1) * parseInt(limit);
  const take = parseInt(limit);

  regionId = await resolveScopedRegionId(actor, regionId);

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

  // The risk-stat header is only consumed on the first page (the client keeps it
  // while paginating), and the per-profile screening scan is only needed when an
  // irdCategory filter is active. Skip the whole block on subsequent pages with
  // no filter — avoids re-scanning every profile + screening on each page turn.
  const isFirstPage = parseInt(page) === 1;
  const needsScreeningData = isFirstPage || !!irdCategory;

  let totalHighRisk = 0;
  let totalAttention = 0;
  let totalNormal = 0;
  let where = userFilter;

  if (needsScreeningData) {
    // 1. Resolve profiles belonging to users matching the filter (bounded by
    //    profile count, not screening count). Region/search logic stays in Prisma.
    const matchingProfiles = await prisma.familyProfile.findMany({
      where: { user: userFilter },
      select: { id: true, userId: true },
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
    for (const cat of latestScreeningsMap.values()) {
      if (cat === 'high') totalHighRisk++;
      else if (cat === 'attention') totalAttention++;
      else if (cat === 'normal') totalNormal++;
    }

    // 4. Handle filtering by irdCategory — single pass with a Set of matched
    //    profile ids (O(n) instead of O(n²) array.includes per profile).
    if (irdCategory) {
      const matchedProfileIds = new Set();
      for (const [profileId, cat] of latestScreeningsMap.entries()) {
        if (cat === irdCategory) matchedProfileIds.add(profileId);
      }
      const matchedUserIds = new Set();
      for (const p of matchingProfiles) {
        if (matchedProfileIds.has(p.id)) matchedUserIds.add(p.userId);
      }
      where = { ...userFilter, id: { in: Array.from(matchedUserIds) } };
    }
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
  const searchLower = search ? search.toLowerCase() : null;
  const data = users.map((user) => {
    const allScreenings = user.familyProfiles.flatMap((p) => p.screenings);
    const latest = allScreenings.sort((a, b) => new Date(b.screeningAt) - new Date(a.screeningAt))[0];

    // When the account itself doesn't name-match the search, but a family
    // member does, surface that member's name so admins searching by a
    // profile name don't land on an opaque account row (e.g. an org account
    // with 100+ members) and have to scroll to find who they searched for.
    // All members whose name matches (not just the first) so an org account
    // with several matches surfaces each one, not one arbitrary hit.
    let matchedProfiles = [];
    if (searchLower && !user.responsibleName?.toLowerCase().includes(searchLower)) {
      matchedProfiles = user.familyProfiles
        .filter((p) => p.name?.toLowerCase().includes(searchLower))
        .map((p) => ({ id: p.id, name: p.name }));
    }
    // matchedProfile kept for older app builds (first match).
    const matchedProfile = matchedProfiles[0] || null;

    return {
      id: user.id,
      name: user.responsibleName,
      nik: user.kkNumber,
      phone: user.phone,
      avatarPath: user.avatarPath || null,
      createdAt: user.createdAt,
      latestIrd: latest || null,
      matchedProfile,
      matchedProfiles,
    };
  });

  return { data, total, totalHighRisk, totalAttention, totalNormal, page: parseInt(page), limit: take };
};

const getPatientDetail = async (id, actor = {}) => {
  // ADMIN may only open patients inside their own region subtree; outside =>
  // 404 (no cross-region enumeration). SUPERADMIN is unrestricted.
  const where = { id, role: 'PATIENT' };
  if (actor?.role === 'ADMIN') {
    const me = await prisma.user.findUnique({ where: { id: actor.id }, select: { regionId: true } });
    if (!me?.regionId) throw Object.assign(new Error('Patient not found'), { statusCode: 404 });
    Object.assign(where, regionScopeFilter(me.regionId));
  }
  const user = await prisma.user.findFirst({
    where,
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
          // Perilaku defaults — the screening form prefills from these
          smokingStatus: true,
          physicalActivity: true,
          fruitConsumption: true,
          vegetableConsumption: true,
          sweetFoodConsumption: true,
          sweetDrinkConsumption: true,
          fattyFoodConsumption: true,
          fastFoodConsumption: true,
          sleepDuration: true,
          medicationRoutine: true,
          metrics: {
            orderBy: { recordedAt: 'desc' },
            take: 50,
            select: {
              id: true,
              type: true,
              value: true,
              secondaryValue: true,
              unit: true,
              notes: true,
              recordedAt: true,
            },
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
