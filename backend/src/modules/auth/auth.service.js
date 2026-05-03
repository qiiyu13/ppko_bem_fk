const { hashPassword, comparePassword } = require('../../utils/password');
const { generateToken } = require('../../utils/jwt');
const { verifyFirebaseToken } = require('../../utils/firebase');

const prisma = require('../../utils/prisma');

const register = async ({ kkNumber, responsibleName, password, phone }) => {
  const existing = await prisma.user.findUnique({ where: { kkNumber } });
  if (existing) throw Object.assign(new Error('KK number already registered'), { code: 'P2002' });

  const hashedPassword = await hashPassword(password);
  const user = await prisma.user.create({
    data: { kkNumber, responsibleName, password: hashedPassword, phone },
    select: { id: true, kkNumber: true, responsibleName: true, role: true },
  });

  const token = generateToken({ userId: user.id, role: user.role });
  return { user, token };
};

const login = async ({ kkNumber, password }) => {
  const user = await prisma.user.findUnique({ where: { kkNumber } });
  if (!user) throw Object.assign(new Error('Invalid credentials'), { statusCode: 401 });

  const valid = await comparePassword(password, user.password);
  if (!valid) throw Object.assign(new Error('Invalid credentials'), { statusCode: 401 });

  const token = generateToken({ userId: user.id, role: user.role });
  return {
    user: { id: user.id, kkNumber: user.kkNumber, responsibleName: user.responsibleName, role: user.role },
    token,
  };
};

const getMe = async (userId) => {
  const user = await prisma.user.findUnique({
    where: { id: userId },
    select: { id: true, kkNumber: true, responsibleName: true, phone: true, role: true },
  });
  if (!user) throw Object.assign(new Error('User not found'), { statusCode: 404 });
  return user;
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

module.exports = { register, login, getMe, forgotPassword, resetPassword };
