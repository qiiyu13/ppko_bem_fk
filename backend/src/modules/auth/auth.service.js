const { hashPassword, comparePassword } = require('../../utils/password');
const { generateToken } = require('../../utils/jwt');
const { verifyFirebaseToken } = require('../../utils/firebase');

const prisma = require('../../utils/prisma');

// Race-safe find-or-create for a region row. The common path (region already
// exists) is a single indexed read. On a miss we create; if a concurrent
// register created the same (type, name, parentId) first, the @@unique
// constraint rejects our insert with P2002 and we re-read the winner instead of
// silently duplicating the RW/RT row.
const findOrCreateRegion = async (type, name, parentId) => {
  const existing = await prisma.region.findFirst({ where: { type, name, parentId } });
  if (existing) return existing;
  try {
    return await prisma.region.create({ data: { type, name, parentId } });
  } catch (err) {
    if (err.code === 'P2002') {
      return prisma.region.findFirst({ where: { type, name, parentId } });
    }
    throw err;
  }
};

const register = async ({ kkNumber, responsibleName, password, phone, villageId, rwNumber, rtNumber }) => {
  const existing = await prisma.user.findUnique({ where: { kkNumber } });
  if (existing) throw Object.assign(new Error('KK number already registered'), { code: 'P2002' });

  let regionId = null;
  if (villageId && rwNumber && rtNumber) {
    // parseInt first: the validator accepts "01"/"001" as integers, and
    // padding the raw string would mint "RW 001" as a separate region row.
    const rwName = `RW ${String(parseInt(rwNumber, 10)).padStart(2, '0')}`;
    const rtName = `RT ${String(parseInt(rtNumber, 10)).padStart(2, '0')}`;

    const rw = await findOrCreateRegion('RW', rwName, villageId);
    const rt = await findOrCreateRegion('RT', rtName, rw.id);

    regionId = rt.id;
  }

  const hashedPassword = await hashPassword(password);
  const user = await prisma.user.create({
    data: { kkNumber, responsibleName, password: hashedPassword, phone, regionId },
    select: { id: true, kkNumber: true, responsibleName: true, role: true },
  });

  const authAt = Math.floor(Date.now() / 1000);
  const token = generateToken({ userId: user.id, role: user.role, authAt });
  return { user, token };
};

const login = async ({ identifier, password }) => {
  const isKK = /^\d{16}$/.test(identifier);
  const user = isKK
    ? await prisma.user.findUnique({ where: { kkNumber: identifier } })
    : await prisma.user.findUnique({ where: { username: identifier } });

  if (!user) throw Object.assign(new Error('Invalid credentials'), { statusCode: 401 });

  // KK login: patients only. Username login: any role that has one set - most
  // patients don't (self-register only collects kkNumber), but an
  // admin-provisioned org account (e.g. Sekolah Lansia) can be a PATIENT with
  // a username instead of a KK number.
  if (isKK && user.role !== 'PATIENT') throw Object.assign(new Error('Invalid credentials'), { statusCode: 401 });

  const valid = await comparePassword(password, user.password);
  if (!valid) throw Object.assign(new Error('Invalid credentials'), { statusCode: 401 });

  // Deactivated accounts cannot obtain a token. Generic error to avoid
  // distinguishing "disabled" from "wrong password" (no enumeration).
  if (!user.isActive) throw Object.assign(new Error('Invalid credentials'), { statusCode: 401 });

  const authAt = Math.floor(Date.now() / 1000);
  const token = generateToken({ userId: user.id, role: user.role, authAt });
  return {
    user: { id: user.id, kkNumber: user.kkNumber, username: user.username, responsibleName: user.responsibleName, role: user.role },
    token,
  };
};

const getMe = async (userId) => {
  const user = await prisma.user.findUnique({
    where: { id: userId },
    select: {
      id: true, kkNumber: true, responsibleName: true, phone: true, role: true,
      position: true, avatarPath: true, createdAt: true, updatedAt: true,
      region: { select: { id: true, name: true } },
    },
  });
  if (!user) throw Object.assign(new Error('User not found'), { statusCode: 404 });
  return user;
};

// Lean lookup for the refresh path: just the fields needed to decide whether a
// new token may be minted. Avoids pulling the full profile that getMe returns.
const getAccountStatus = async (userId) => {
  return prisma.user.findUnique({
    where: { id: userId },
    select: { id: true, role: true, isActive: true },
  });
};

// Self-service profile update. Field whitelist is the security boundary here:
// role/isActive/regionId must never be settable through this path — privileged
// changes go through /admin/users which enforces actor-role checks.
const updateMe = async (userId, data) => {
  const updateData = {};
  if (data.responsibleName !== undefined) updateData.responsibleName = data.responsibleName;
  if (data.position !== undefined) updateData.position = data.position || null;
  if (data.phone !== undefined) updateData.phone = data.phone || null;
  if (data.password) updateData.password = await hashPassword(data.password);

  return prisma.user.update({
    where: { id: userId },
    data: updateData,
    select: {
      id: true, kkNumber: true, responsibleName: true, phone: true, role: true,
      position: true, avatarPath: true, createdAt: true, updatedAt: true,
      region: { select: { id: true, name: true } },
    },
  });
};

const updateAvatar = async (userId, avatarPath) => {
  await prisma.user.update({
    where: { id: userId },
    data: { avatarPath },
  });
};

const forgotPassword = async ({ kkNumber }) => {
  // Always return the same response whether or not the KK exists / phone matches,
  // to prevent account enumeration. The lookup is run (result intentionally
  // unused) so response timing does not leak existence. Real verification happens
  // at resetPassword: the Firebase OTP proves phone ownership and the stored
  // phone must match the verified number.
  await prisma.user.findUnique({ where: { kkNumber } });
  return { message: 'If the data matches, an OTP has been sent to the registered phone number.' };
};

const resetPassword = async ({ kkNumber, firebaseToken, newPassword }) => {
  const decoded = await verifyFirebaseToken(firebaseToken);
  if (!decoded.phone_number) {
    throw Object.assign(new Error('Invalid verification token'), { statusCode: 400 });
  }

  const user = await prisma.user.findUnique({ where: { kkNumber } });
  if (!user) throw Object.assign(new Error('KK number not found'), { statusCode: 404 });

  const normalizedStored = user.phone?.replace(/^0/, '+62');
  const normalizedFirebase = decoded.phone_number;
  if (normalizedStored !== normalizedFirebase) {
    throw Object.assign(new Error('Phone number mismatch'), { statusCode: 400 });
  }

  const hashedPassword = await hashPassword(newPassword);
  await prisma.user.update({
    where: { kkNumber },
    data: { password: hashedPassword },
  });

  return { message: 'Password reset successful' };
};

module.exports = { register, login, getMe, getAccountStatus, updateMe, updateAvatar, forgotPassword, resetPassword };
