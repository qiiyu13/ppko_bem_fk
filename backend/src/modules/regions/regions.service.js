const prisma = require('../../utils/prisma');
const { parsePagination } = require('../../utils/pagination');

const getRegions = async (query) => {
  const { page, limit, skip } = parsePagination(query);
  const [data, total] = await Promise.all([
    prisma.region.findMany({
      skip, take: limit,
      include: {
        parent: { select: { id: true, name: true, type: true } },
        children: {
          select: {
            id: true, name: true, type: true,
            _count: { select: { users: true } },
          },
        },
        _count: { select: { users: true } },
      },
      orderBy: { createdAt: 'asc' },
    }),
    prisma.region.count(),
  ]);
  return { data, total, page, limit };
};

const createRegion = async (data) => {
  return prisma.region.create({
    data: {
      type: data.type,
      name: data.name,
      parentId: data.parentId || null,
    },
  });
};

const getStats = async () => {
  const [rwCount, rtCount, familyCount, profileCount] = await Promise.all([
    prisma.region.count({ where: { type: 'RW' } }),
    prisma.region.count({ where: { type: 'RT' } }),
    prisma.user.count({ where: { role: 'PATIENT' } }),
    prisma.familyProfile.count(),
  ]);
  return { rwCount, rtCount, familyCount, profileCount };
};

const getUsersByRegion = async (regionId, query) => {
  const { page, limit, skip } = parsePagination(query);
  const where = { regionId };
  const [data, total] = await Promise.all([
    prisma.user.findMany({
      where, skip, take: limit,
      orderBy: { createdAt: 'desc' },
      select: {
        id: true,
        kkNumber: true,
        responsibleName: true,
        phone: true,
        isActive: true,
        role: true,
        createdAt: true,
        updatedAt: true,
        _count: { select: { familyProfiles: true } },
      },
    }),
    prisma.user.count({ where }),
  ]);
  return { data, total, page, limit };
};

module.exports = { getRegions, createRegion, getStats, getUsersByRegion };
