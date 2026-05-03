const prisma = require('./prisma');

const MAX_ATTEMPTS = 5;
const LOCKOUT_DURATION = 15 * 60 * 1000;
const CODE_EXPIRY = 15 * 60 * 1000;

async function setCode(kkNumber, code) {
  await prisma.passwordReset.upsert({
    where: { kkNumber },
    update: { code, expiresAt: new Date(Date.now() + CODE_EXPIRY), attempts: 0, lockedUntil: null },
    create: { kkNumber, code, expiresAt: new Date(Date.now() + CODE_EXPIRY) },
  });
}

async function verifyCode(kkNumber, code) {
  const stored = await prisma.passwordReset.findUnique({ where: { kkNumber } });
  if (!stored) return { valid: false, error: 'No reset code requested' };
  if (stored.lockedUntil && stored.lockedUntil > new Date()) {
    const remaining = Math.ceil((stored.lockedUntil - new Date()) / 60000);
    return { valid: false, error: `Too many attempts. Try again in ${remaining} minutes.` };
  }
  if (new Date() > stored.expiresAt) {
    await prisma.passwordReset.delete({ where: { kkNumber } });
    return { valid: false, error: 'Reset code expired' };
  }
  if (stored.code !== code) {
    const newAttempts = stored.attempts + 1;
    const updateData = { attempts: newAttempts };
    if (newAttempts >= MAX_ATTEMPTS) {
      updateData.lockedUntil = new Date(Date.now() + LOCKOUT_DURATION);
      updateData.attempts = 0;
    }
    await prisma.passwordReset.update({ where: { kkNumber }, data: updateData });
    return { valid: false, error: 'Invalid reset code' };
  }
  return { valid: true };
}

async function consumeCode(kkNumber) {
  await prisma.passwordReset.deleteMany({ where: { kkNumber } });
}

module.exports = { setCode, verifyCode, consumeCode };
