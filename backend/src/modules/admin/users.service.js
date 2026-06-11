const { hashPassword } = require('../../utils/password');
const { parsePagination } = require('../../utils/pagination');
const { regionScopeFilter } = require('../../utils/regionScope');

const prisma = require('../../utils/prisma');

const USER_SELECT = {
  id: true, kkNumber: true, username: true, responsibleName: true, position: true, phone: true, role: true, isActive: true,
  avatarPath: true, regionId: true, createdAt: true, updatedAt: true,
  region: { select: { id: true, name: true, type: true } },
};

// Only a SUPERADMIN may create, modify, or delete ADMIN/SUPERADMIN accounts, or
// assign those roles. A plain ADMIN is confined to PATIENT accounts. Throwing
// here closes the privilege-escalation path where an ADMIN could mint or
// promote itself to SUPERADMIN through the shared user-management routes.
const assertCanManageRole = (actorRole, targetRole) => {
  if (actorRole !== 'SUPERADMIN' && (targetRole === 'ADMIN' || targetRole === 'SUPERADMIN')) {
    throw Object.assign(new Error('Only a superadmin can manage admin accounts'), { statusCode: 403 });
  }
};

// Resolve an ADMIN actor's own region. Admins are region-scoped; an admin with
// no region is misconfigured and must fail closed (see nothing / manage nobody)
// rather than fall back to global access.
const getActorRegionId = async (actorId) => {
  const me = await prisma.user.findUnique({ where: { id: actorId }, select: { regionId: true } });
  return me?.regionId || null;
};

const getUsers = async (role, query = {}, actor = {}) => {
  const where = {};
  if (role) where.role = role;

  // ADMIN: confined to PATIENT accounts within their own region subtree.
  if (actor.role === 'ADMIN') {
    const regionId = await getActorRegionId(actor.id);
    if (!regionId) return [];
    where.role = 'PATIENT';
    Object.assign(where, regionScopeFilter(regionId));
  }

  // Paginate when the client asks; otherwise cap to avoid unbounded scans.
  if (query.page !== undefined || query.limit !== undefined) {
    const { page, limit, skip } = parsePagination(query);
    const [data, total] = await Promise.all([
      prisma.user.findMany({ where, skip, take: limit, orderBy: { createdAt: 'desc' }, select: USER_SELECT }),
      prisma.user.count({ where }),
    ]);
    return { data, total, page, limit };
  }

  return prisma.user.findMany({
    where,
    orderBy: { createdAt: 'desc' },
    take: 200,
    select: USER_SELECT,
  });
};

const createUser = async (data, actor = {}) => {
  const role = data.role || 'ADMIN';
  const isAdminRole = role === 'ADMIN' || role === 'SUPERADMIN';

  assertCanManageRole(actor.role, role);

  // ADMIN-created accounts are forced into the admin's own region; client-supplied
  // regionId is ignored so an admin cannot place a user outside their scope.
  let regionId = data.regionId || null;
  if (actor.role === 'ADMIN') {
    const actorRegionId = await getActorRegionId(actor.id);
    if (!actorRegionId) throw Object.assign(new Error('Your account is not assigned to a region'), { statusCode: 403 });
    regionId = actorRegionId;
  }

  // An ADMIN must be region-scoped, otherwise region enforcement fails closed and
  // the new admin can see nobody. SUPERADMIN is global and needs no region.
  if (role === 'ADMIN' && !regionId) {
    throw Object.assign(new Error('regionId is required for an admin account'), { statusCode: 400 });
  }

  if (isAdminRole) {
    if (!data.username) throw Object.assign(new Error('Username is required for admin/superadmin'), { statusCode: 400 });
    const existing = await prisma.user.findUnique({ where: { username: data.username } });
    if (existing) throw Object.assign(new Error('Username already taken'), { code: 'P2002' });
  } else {
    if (!data.kkNumber) throw Object.assign(new Error('KK number is required for patients'), { statusCode: 400 });
    const existing = await prisma.user.findUnique({ where: { kkNumber: data.kkNumber } });
    if (existing) throw Object.assign(new Error('KK number already registered'), { code: 'P2002' });
  }

  const hashedPassword = await hashPassword(data.password);
  return prisma.user.create({
    data: {
      kkNumber: isAdminRole ? null : data.kkNumber,
      username: isAdminRole ? data.username : null,
      responsibleName: data.responsibleName,
      position: data.position || null,
      password: hashedPassword,
      phone: data.phone || null,
      role,
      isActive: data.isActive !== undefined ? data.isActive : true,
      regionId,
    },
    select: {
      id: true, kkNumber: true, username: true, responsibleName: true, position: true, phone: true, role: true, isActive: true,
      regionId: true, createdAt: true,
      region: { select: { id: true, name: true, type: true } },
    },
  });
};

const updateUser = async (id, data, actor = {}) => {
  // Load the target's role/region to enforce who may touch it. For an ADMIN,
  // scope the lookup to their region subtree so a cross-region (or admin/superadmin)
  // target is indistinguishable from a missing one (404, no enumeration).
  let target;
  if (actor.role === 'ADMIN') {
    const actorRegionId = await getActorRegionId(actor.id);
    if (!actorRegionId) throw Object.assign(new Error('User not found'), { code: 'P2025' });
    target = await prisma.user.findFirst({
      where: { id, role: 'PATIENT', ...regionScopeFilter(actorRegionId) },
      select: { id: true, role: true },
    });
  } else {
    target = await prisma.user.findUnique({ where: { id }, select: { id: true, role: true } });
  }
  if (!target) throw Object.assign(new Error('User not found'), { code: 'P2025' });

  // ADMIN may not edit ADMIN/SUPERADMIN rows, nor promote anyone into those roles.
  assertCanManageRole(actor.role, target.role);
  if (data.role !== undefined) assertCanManageRole(actor.role, data.role);
  // An ADMIN cannot move a user out of (or into a different) region.
  if (actor.role === 'ADMIN' && data.regionId !== undefined) {
    throw Object.assign(new Error('Cannot reassign region'), { statusCode: 403 });
  }

  const updateData = {};
  if (data.responsibleName !== undefined) updateData.responsibleName = data.responsibleName;
  if (data.position !== undefined) updateData.position = data.position || null;
  if (data.username !== undefined) updateData.username = data.username || null;
  if (data.phone !== undefined) updateData.phone = data.phone || null;
  if (data.role !== undefined) updateData.role = data.role;
  if (data.isActive !== undefined) updateData.isActive = data.isActive;
  if (data.password) updateData.password = await hashPassword(data.password);
  if (data.regionId !== undefined) updateData.regionId = data.regionId || null;

  return prisma.user.update({
    where: { id },
    data: updateData,
    select: {
      id: true, kkNumber: true, username: true, responsibleName: true, position: true, phone: true, role: true, isActive: true,
      regionId: true, createdAt: true, updatedAt: true,
      region: { select: { id: true, name: true, type: true } },
    },
  });
};

const deleteUser = async (id, actor = {}) => {
  const user = await prisma.user.findUnique({
    where: { id },
    include: {
      familyProfiles: { select: { id: true } },
    },
  });
  if (!user) throw Object.assign(new Error('User not found'), { code: 'P2025' });

  // ADMIN may only delete PATIENTs within their own region; everything else is a 404.
  assertCanManageRole(actor.role, user.role);
  if (actor.role === 'ADMIN') {
    const actorRegionId = await getActorRegionId(actor.id);
    const inScope = actorRegionId && await prisma.user.findFirst({
      where: { id, ...regionScopeFilter(actorRegionId) },
      select: { id: true },
    });
    if (!inScope) throw Object.assign(new Error('User not found'), { code: 'P2025' });
  }

  const profileIds = user.familyProfiles.map((p) => p.id);

  await prisma.$transaction(async (tx) => {
    if (profileIds.length) {
      await tx.medicalScreening.deleteMany({ where: { profileId: { in: profileIds } } });
      await tx.healthMetric.deleteMany({ where: { profileId: { in: profileIds } } });
    }
    await tx.familyProfile.deleteMany({ where: { userId: id } });

    await tx.appointment.deleteMany({ where: { userId: id } });

    await tx.article.deleteMany({ where: { authorId: id } });

    await tx.user.delete({ where: { id } });
  });

  return { message: 'User deleted successfully' };
};

module.exports = { getUsers, createUser, updateUser, deleteUser };
