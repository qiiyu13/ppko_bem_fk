const { hashPassword } = require('../../utils/password');

const prisma = require('../../utils/prisma');

const getUsers = async (role) => {
  const where = {};
  if (role) where.role = role;

  return prisma.user.findMany({
    where,
    orderBy: { createdAt: 'desc' },
    select: { id: true, nik: true, name: true, role: true, isActive: true, createdAt: true },
  });
};

const createUser = async (data) => {
  const existing = await prisma.user.findUnique({ where: { nik: data.nik } });
  if (existing) throw Object.assign(new Error('NIK already registered'), { code: 'P2002' });

  const hashedPassword = await hashPassword(data.password);
  return prisma.user.create({
    data: {
      nik: data.nik,
      name: data.name,
      password: hashedPassword,
      gender: data.gender || null,
      birthDate: data.birthDate ? new Date(data.birthDate) : null,
      phone: data.phone || null,
      role: data.role || 'ADMIN',
      isActive: data.isActive !== undefined ? data.isActive : true,
    },
    select: { id: true, nik: true, name: true, role: true, isActive: true, createdAt: true },
  });
};

const updateUser = async (id, data) => {
  const updateData = {};
  if (data.name !== undefined) updateData.name = data.name;
  if (data.gender !== undefined) updateData.gender = data.gender;
  if (data.birthDate !== undefined) updateData.birthDate = new Date(data.birthDate);
  if (data.phone !== undefined) updateData.phone = data.phone || null;
  if (data.role !== undefined) updateData.role = data.role;
  if (data.isActive !== undefined) updateData.isActive = data.isActive;
  if (data.password) updateData.password = await hashPassword(data.password);

  return prisma.user.update({
    where: { id },
    data: updateData,
    select: { id: true, nik: true, name: true, role: true, isActive: true, createdAt: true },
  });
};

const deleteUser = async (id) => {
  await prisma.user.delete({ where: { id } });
  return { message: 'User deleted successfully' };
};

module.exports = { getUsers, createUser, updateUser, deleteUser };
