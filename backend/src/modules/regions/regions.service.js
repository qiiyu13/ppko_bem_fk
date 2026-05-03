const prisma = require('../../utils/prisma');
const { parsePagination } = require('../../utils/pagination');

const getRegions = async (query) => {
  const { page, limit, skip } = parsePagination(query);
  const [data, total] = await Promise.all([
    prisma.region.findMany({
      skip, take: limit,
      include: {
        parent: { select: { id: true, name: true, type: true } },
        children: { select: { id: true, name: true, type: true } },
        _count: { select: { residents: true } },
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

const getResidents = async (regionId, query) => {
  const { page, limit, skip } = parsePagination(query);
  const where = regionId ? { regionId } : {};
  const [data, total] = await Promise.all([
    prisma.resident.findMany({
      where, skip, take: limit,
      include: { region: { select: { name: true, type: true } } },
      orderBy: { createdAt: 'desc' },
    }),
    prisma.resident.count({ where }),
  ]);
  return { data, total, page, limit };
};

const createResident = async (data) => {
  return prisma.resident.create({
    data: {
      regionId: data.regionId,
      name: data.name,
      nik: data.nik,
      gender: data.gender,
      birthDate: new Date(data.birthDate),
      phone: data.phone || null,
      address: data.address || null,
    },
  });
};

const updateResident = async (id, data) => {
  const updateData = {};
  if (data.regionId !== undefined) updateData.regionId = data.regionId;
  if (data.name !== undefined) updateData.name = data.name;
  if (data.nik !== undefined) updateData.nik = data.nik;
  if (data.gender !== undefined) updateData.gender = data.gender;
  if (data.birthDate !== undefined) updateData.birthDate = new Date(data.birthDate);
  if (data.phone !== undefined) updateData.phone = data.phone || null;
  if (data.address !== undefined) updateData.address = data.address || null;

  return prisma.resident.update({ where: { id }, data: updateData });
};

module.exports = { getRegions, createRegion, getResidents, createResident, updateResident };
