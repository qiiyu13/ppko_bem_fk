const { broadcastToUsers, broadcastToAll, events } = require('../../websocket');
const { accessibleWhere, getAccessibleProfile } = require('../../utils/profileAccess');

const prisma = require('../../utils/prisma');

const getProfiles = async (userId) => {
  return prisma.familyProfile.findMany({
    where: accessibleWhere(userId),
    orderBy: { createdAt: 'asc' },
  });
};

const getProfile = async (id, userId) => {
  const profile = await getAccessibleProfile(id, userId);
  if (!profile) throw Object.assign(new Error('Profile not found'), { statusCode: 404 });
  return profile;
};

const createProfile = async (data, userId) => {
  const result = await prisma.familyProfile.create({
    data: {
      userId,
      name: data.name,
      nik: data.nik,
      gender: data.gender,
      birthDate: data.birthDate ? new Date(data.birthDate) : null,
      height: data.height ? parseFloat(data.height) : null,
      weight: data.weight ? parseFloat(data.weight) : null,
      avatarPath: data.avatarPath || null,
      bloodType: data.bloodType || null,
      phone: data.phone || null,
    },
  });
  try { broadcastToUsers([userId], events.DATA_UPDATE, { type: 'profiles', action: 'create', id: result.id }); } catch (e) { console.error('WebSocket broadcast failed:', e.message); }
  return result;
};

// Access gate (owner or linked account) that prefers the row conflictDetection
// already fetched (req.existingRecord) over a second read.
const assertAccess = async (id, userId, existing) => {
  if (existing) {
    if (existing.userId === userId) return existing;
    const link = await prisma.profileLink.findFirst({ where: { profileId: id, userId } });
    if (!link) throw Object.assign(new Error('Profile not found'), { statusCode: 404 });
    return existing;
  }
  return getProfile(id, userId);
};

// Delete stays owner-only - a linked account shouldn't be able to remove a
// profile other accounts depend on.
const assertOwnership = async (id, userId, existing) => {
  if (existing) {
    if (existing.userId !== userId) throw Object.assign(new Error('Profile not found'), { statusCode: 404 });
    return existing;
  }
  const profile = await prisma.familyProfile.findFirst({ where: { id, userId, mergedIntoId: null } });
  if (!profile) throw Object.assign(new Error('Profile not found'), { statusCode: 404 });
  return profile;
};

// Folds `losing` into `canonical` (whichever profile was created first) when
// two accounts' profiles turn out to share a NIK - e.g. a Sekolah Lansia org
// account and the same lansia's family account both registered the same
// person separately. All health history moves onto the canonical row, the
// losing account gets linked to it instead of owning a duplicate, and the
// losing row is soft-deleted (mergedIntoId) rather than dropped.
const mergeProfiles = async (a, b, canonicalUpdateData, requestingUserId) => {
  const [canonical, losing] = a.createdAt <= b.createdAt ? [a, b] : [b, a];

  const result = await prisma.$transaction(async (tx) => {
    if (canonical.id === a.id && Object.keys(canonicalUpdateData).length) {
      await tx.familyProfile.update({ where: { id: canonical.id }, data: canonicalUpdateData });
    }

    await tx.healthMetric.updateMany({ where: { profileId: losing.id }, data: { profileId: canonical.id } });
    await tx.medicalScreening.updateMany({ where: { profileId: losing.id }, data: { profileId: canonical.id } });
    await tx.appointment.updateMany({ where: { profileId: losing.id }, data: { profileId: canonical.id } });

    const carryOverUserIds = new Set([losing.userId]);
    const losingLinks = await tx.profileLink.findMany({ where: { profileId: losing.id } });
    for (const link of losingLinks) carryOverUserIds.add(link.userId);
    carryOverUserIds.delete(canonical.userId);

    for (const linkedUserId of carryOverUserIds) {
      await tx.profileLink.upsert({
        where: { profileId_userId: { profileId: canonical.id, userId: linkedUserId } },
        update: {},
        create: { profileId: canonical.id, userId: linkedUserId, role: 'family' },
      });
    }
    await tx.profileLink.deleteMany({ where: { profileId: losing.id } });

    await tx.familyProfile.update({ where: { id: losing.id }, data: { mergedIntoId: canonical.id } });

    return tx.familyProfile.findUnique({ where: { id: canonical.id } });
  });

  try {
    broadcastToUsers([canonical.userId, losing.userId, requestingUserId], events.DATA_UPDATE, { type: 'profiles', action: 'merge', id: canonical.id });
  } catch (e) { console.error('WebSocket broadcast failed:', e.message); }

  return result;
};

const updateProfile = async (id, data, userId, existing) => {
  const current = await assertAccess(id, userId, existing);

  const updateData = {};
  if (data.name !== undefined) updateData.name = data.name;
  if (data.nik !== undefined) updateData.nik = data.nik;
  if (data.gender !== undefined) updateData.gender = data.gender;
  if (data.birthDate !== undefined) updateData.birthDate = data.birthDate ? new Date(data.birthDate) : null;
  if (data.height !== undefined) updateData.height = data.height ? parseFloat(data.height) : null;
  if (data.weight !== undefined) updateData.weight = data.weight ? parseFloat(data.weight) : null;
  if (data.avatarPath !== undefined) updateData.avatarPath = data.avatarPath || null;
  if (data.bloodType !== undefined) updateData.bloodType = data.bloodType || null;
  if (data.phone !== undefined) updateData.phone = data.phone || null;

  if (data.nik && data.nik !== current.nik) {
    const match = await prisma.familyProfile.findFirst({
      where: { nik: data.nik, id: { not: id }, mergedIntoId: null },
    });
    if (match) return mergeProfiles(current, match, updateData, userId);
  }

  const result = await prisma.familyProfile.update({
    where: { id },
    data: updateData,
  });
  try { broadcastToUsers([userId], events.DATA_UPDATE, { type: 'profiles', action: 'update', id }); } catch (e) { console.error('WebSocket broadcast failed:', e.message); }
  return result;
};

const deleteProfile = async (id, userId, existing) => {
  await assertOwnership(id, userId, existing);

  await prisma.$transaction([
    prisma.healthMetric.deleteMany({ where: { profileId: id } }),
    prisma.medicalScreening.deleteMany({ where: { profileId: id } }),
    prisma.profileLink.deleteMany({ where: { profileId: id } }),
    prisma.familyProfile.delete({ where: { id } }),
  ]);

  try { broadcastToUsers([userId], events.DATA_UPDATE, { type: 'profiles', action: 'delete', id }); } catch (e) { console.error('WebSocket broadcast failed:', e.message); }
  return { message: 'Profile deleted successfully' };
};

module.exports = { getProfiles, getProfile, createProfile, updateProfile, deleteProfile };
