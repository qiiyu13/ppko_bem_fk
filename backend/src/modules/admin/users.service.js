const { hashPassword } = require('../../utils/password');

const prisma = require('../../utils/prisma');

const getUsers = async (role) => {
  const where = {};
  if (role) where.role = role;

  return prisma.user.findMany({
    where,
    orderBy: { createdAt: 'desc' },
    select: {
      id: true, kkNumber: true, responsibleName: true, role: true, isActive: true,
      regionId: true, createdAt: true, updatedAt: true,
      region: { select: { id: true, name: true, type: true } },
    },
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
      regionId: data.regionId || null,
    },
    select: {
      id: true, kkNumber: true, responsibleName: true, role: true, isActive: true,
      regionId: true, createdAt: true,
      region: { select: { id: true, name: true, type: true } },
    },
  });
};

const updateUser = async (id, data) => {
  const updateData = {};
  if (data.responsibleName !== undefined) updateData.responsibleName = data.responsibleName;
  if (data.phone !== undefined) updateData.phone = data.phone || null;
  if (data.role !== undefined) updateData.role = data.role;
  if (data.isActive !== undefined) updateData.isActive = data.isActive;
  if (data.password) updateData.password = await hashPassword(data.password);
  if (data.regionId !== undefined) updateData.regionId = data.regionId || null;

  return prisma.user.update({
    where: { id },
    data: updateData,
    select: {
      id: true, kkNumber: true, responsibleName: true, role: true, isActive: true,
      regionId: true, createdAt: true,
      region: { select: { id: true, name: true, type: true } },
    },
  });
};

const deleteUser = async (id) => {
  const user = await prisma.user.findUnique({
    where: { id },
    include: {
      conversations: { select: { id: true } },
      familyProfiles: { select: { id: true } },
    },
  });
  if (!user) throw Object.assign(new Error('User not found'), { code: 'P2025' });

  await prisma.$transaction(async (tx) => {
    for (const conv of user.conversations) {
      await tx.chatMessage.deleteMany({ where: { conversationId: conv.id } });
    }
    await tx.chatConversation.deleteMany({ where: { userId: id } });

    for (const profile of user.familyProfiles) {
      await tx.medicalScreening.deleteMany({ where: { profileId: profile.id } });
      await tx.healthMetric.deleteMany({ where: { profileId: profile.id } });
    }
    await tx.familyProfile.deleteMany({ where: { userId: id } });

    await tx.appointment.deleteMany({ where: { userId: id } });

    await tx.article.deleteMany({ where: { authorId: id } });

    await tx.user.delete({ where: { id } });
  });

  return { message: 'User deleted successfully' };
};

module.exports = { getUsers, createUser, updateUser, deleteUser };
