const { hashPassword } = require('../../utils/password');

const prisma = require('../../utils/prisma');

const getUsers = async (role) => {
  const where = {};
  if (role) where.role = role;

  return prisma.user.findMany({
    where,
    orderBy: { createdAt: 'desc' },
    select: { id: true, kkNumber: true, responsibleName: true, role: true, isActive: true, createdAt: true },
  });
};

const createUser = async (data) => {
  const existing = await prisma.user.findUnique({ where: { kkNumber: data.kkNumber } });
  if (existing) throw Object.assign(new Error('KK number already registered'), { code: 'P2002' });

  const hashedPassword = await hashPassword(data.password);
  return prisma.user.create({
    data: {
      kkNumber: data.kkNumber,
      responsibleName: data.responsibleName,
      password: hashedPassword,
      phone: data.phone || null,
      role: data.role || 'ADMIN',
      isActive: data.isActive !== undefined ? data.isActive : true,
    },
    select: { id: true, kkNumber: true, responsibleName: true, role: true, isActive: true, createdAt: true },
  });
};

const updateUser = async (id, data) => {
  const updateData = {};
  if (data.responsibleName !== undefined) updateData.responsibleName = data.responsibleName;
  if (data.phone !== undefined) updateData.phone = data.phone || null;
  if (data.role !== undefined) updateData.role = data.role;
  if (data.isActive !== undefined) updateData.isActive = data.isActive;
  if (data.password) updateData.password = await hashPassword(data.password);

  return prisma.user.update({
    where: { id },
    data: updateData,
    select: { id: true, kkNumber: true, responsibleName: true, role: true, isActive: true, createdAt: true },
  });
};

const deleteUser = async (id) => {
  await prisma.user.delete({ where: { id } });
  return { message: 'User deleted successfully' };
};

module.exports = { getUsers, createUser, updateUser, deleteUser };
