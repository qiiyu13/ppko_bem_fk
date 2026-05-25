const { hashPassword, comparePassword } = require('../../utils/password');
const { generateToken } = require('../../utils/jwt');
const { verifyFirebaseToken } = require('../../utils/firebase');

const prisma = require('../../utils/prisma');

const register = async ({ kkNumber, responsibleName, password, phone, villageId, rwNumber, rtNumber }) => {
  const existing = await prisma.user.findUnique({ where: { kkNumber } });
  if (existing) throw Object.assign(new Error('KK number already registered'), { code: 'P2002' });

  let regionId = null;
  if (villageId && rwNumber && rtNumber) {
    const rwName = `RW ${String(rwNumber).padStart(2, '0')}`;
    const rtName = `RT ${String(rtNumber).padStart(2, '0')}`;

    let rw = await prisma.region.findFirst({ where: { type: 'RW', name: rwName, parentId: villageId } });
    if (!rw) rw = await prisma.region.create({ data: { type: 'RW', name: rwName, parentId: villageId } });

    let rt = await prisma.region.findFirst({ where: { type: 'RT', name: rtName, parentId: rw.id } });
    if (!rt) rt = await prisma.region.create({ data: { type: 'RT', name: rtName, parentId: rw.id } });

    regionId = rt.id;
  }

  const hashedPassword = await hashPassword(password);
  const user = await prisma.user.create({
    data: { kkNumber, responsibleName, password: hashedPassword, phone, regionId },
    select: { id: true, kkNumber: true, responsibleName: true, role: true },
  });

  const token = generateToken({ userId: user.id, role: user.role });
  return { user, token };
};

const login = async ({ identifier, password }) => {
  const isKK = /^\d{16}$/.test(identifier);
  const user = isKK
    ? await prisma.user.findUnique({ where: { kkNumber: identifier } })
    : await prisma.user.findUnique({ where: { username: identifier } });

  if (!user) throw Object.assign(new Error('Invalid credentials'), { statusCode: 401 });

  // KK login: patients only. Username login: admin/superadmin only.
  if (isKK && user.role !== 'PATIENT') throw Object.assign(new Error('Invalid credentials'), { statusCode: 401 });
  if (!isKK && user.role === 'PATIENT') throw Object.assign(new Error('Invalid credentials'), { statusCode: 401 });

  const valid = await comparePassword(password, user.password);
  if (!valid) throw Object.assign(new Error('Invalid credentials'), { statusCode: 401 });

  const token = generateToken({ userId: user.id, role: user.role });
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

const updateAvatar = async (userId, avatarPath) => {
  await prisma.user.update({
    where: { id: userId },
    data: { avatarPath },
  });
};

const forgotPassword = async ({ kkNumber, phone }) => {
  const user = await prisma.user.findUnique({ where: { kkNumber } });
  if (!user) throw Object.assign(new Error('KK number not found'), { statusCode: 404 });
  if (user.phone !== phone) throw Object.assign(new Error('Phone number does not match'), { statusCode: 400 });

  return { message: 'OTP sent to your phone number' };
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

module.exports = { register, login, getMe, updateAvatar, forgotPassword, resetPassword };
