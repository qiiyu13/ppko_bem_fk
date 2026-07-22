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
      // Trim + collapse whitespace so " Desa  Sukamaju " and "Desa Sukamaju"
      // can't become two region rows.
      name: data.name.trim().replace(/\s+/g, ' '),
      parentId: data.parentId || null,
    },
  });
};

const getVillages = async () => {
  return prisma.region.findMany({
    where: { type: 'VILLAGE' },
    orderBy: { name: 'asc' },
    select: { id: true, name: true, _count: { select: { children: true } } },
  });
};

const getStats = async () => {
  const [villageCount, rwCount, rtCount, familyCount, profileCount] = await Promise.all([
    prisma.region.count({ where: { type: 'VILLAGE' } }),
    prisma.region.count({ where: { type: 'RW' } }),
    prisma.region.count({ where: { type: 'RT' } }),
    prisma.user.count({ where: { role: 'PATIENT' } }),
    prisma.familyProfile.count(),
  ]);
  return { villageCount, rwCount, rtCount, familyCount, profileCount };
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

module.exports = { getRegions, createRegion, getVillages, getStats, getUsersByRegion };
