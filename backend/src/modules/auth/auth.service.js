const { hashPassword, comparePassword } = require('../../utils/password');
const { generateToken } = require('../../utils/jwt');

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

const resetCodes = new Map();

const forgotPassword = async ({ kkNumber, phone }) => {
  const user = await prisma.user.findUnique({ where: { kkNumber } });
  if (!user) throw Object.assign(new Error('KK number not found'), { statusCode: 404 });
  if (user.phone !== phone) throw Object.assign(new Error('Phone number does not match'), { statusCode: 400 });

  const code = String(Math.floor(100000 + Math.random() * 900000));
  resetCodes.set(kkNumber, { code, expiresAt: Date.now() + 15 * 60 * 1000 });

  console.log(`\n🔐 Reset code for ${kkNumber}: ${code}\n`);

  return { message: 'Reset code sent via SMS' };
};

const resetPassword = async ({ kkNumber, resetCode, newPassword }) => {
  const stored = resetCodes.get(kkNumber);
  if (!stored) throw Object.assign(new Error('No reset code requested'), { statusCode: 400 });
  if (stored.code !== resetCode) throw Object.assign(new Error('Invalid reset code'), { statusCode: 400 });
  if (Date.now() > stored.expiresAt) throw Object.assign(new Error('Reset code expired'), { statusCode: 400 });

  const hashedPassword = await hashPassword(newPassword);
  await prisma.user.update({
    where: { kkNumber },
    data: { password: hashedPassword },
  });

  resetCodes.delete(kkNumber);
  return { message: 'Password reset successful' };
};

module.exports = { register, login, getMe, forgotPassword, resetPassword };
