const { PrismaClient } = require('@prisma/client');
const { hashPassword, comparePassword } = require('../../utils/password');
const { generateToken } = require('../../utils/jwt');

const prisma = new PrismaClient();

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

module.exports = { register, login, getMe };
