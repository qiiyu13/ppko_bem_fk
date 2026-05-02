const { PrismaClient } = require('@prisma/client');

const prisma = new PrismaClient();

const getProfiles = async (userId) => {
  return prisma.familyProfile.findMany({
    where: { userId },
    orderBy: { createdAt: 'desc' },
  });
};

const getProfile = async (id, userId) => {
  const profile = await prisma.familyProfile.findFirst({
    where: { id, userId },
  });
  if (!profile) throw Object.assign(new Error('Profile not found'), { statusCode: 404 });
  return profile;
};

const createProfile = async (data, userId) => {
  return prisma.familyProfile.create({
    data: {
      userId,
      name: data.name,
      nik: data.nik,
      gender: data.gender,
      birthDate: new Date(data.birthDate),
      height: data.height ? parseFloat(data.height) : null,
      weight: data.weight ? parseFloat(data.weight) : null,
      bloodType: data.bloodType || null,
      phone: data.phone || null,
    },
  });
};

const updateProfile = async (id, data, userId) => {
  await getProfile(id, userId); // verify ownership

  const updateData = {};
  if (data.name !== undefined) updateData.name = data.name;
  if (data.nik !== undefined) updateData.nik = data.nik;
  if (data.gender !== undefined) updateData.gender = data.gender;
  if (data.birthDate !== undefined) updateData.birthDate = new Date(data.birthDate);
  if (data.height !== undefined) updateData.height = data.height ? parseFloat(data.height) : null;
  if (data.weight !== undefined) updateData.weight = data.weight ? parseFloat(data.weight) : null;
  if (data.bloodType !== undefined) updateData.bloodType = data.bloodType || null;
  if (data.phone !== undefined) updateData.phone = data.phone || null;

  return prisma.familyProfile.update({
    where: { id },
    data: updateData,
  });
};

const deleteProfile = async (id, userId) => {
  await getProfile(id, userId); // verify ownership
  // Delete associated metrics first to avoid FK constraint
  await prisma.healthMetric.deleteMany({ where: { profileId: id } });
  // Delete associated screenings
  await prisma.medicalScreening.deleteMany({ where: { profileId: id } });
  await prisma.familyProfile.delete({ where: { id } });
  return { message: 'Profile deleted successfully' };
};

module.exports = { getProfiles, getProfile, createProfile, updateProfile, deleteProfile };
