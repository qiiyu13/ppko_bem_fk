const resetCodes = new Map();
const attemptCounts = new Map();

const MAX_ATTEMPTS = 5;
const LOCKOUT_DURATION = 15 * 60 * 1000;
const CODE_EXPIRY = 15 * 60 * 1000;

function setCode(kkNumber, code) {
  resetCodes.set(kkNumber, { code, expiresAt: Date.now() + CODE_EXPIRY });
  attemptCounts.delete(kkNumber);
}

function verifyCode(kkNumber, code) {
  const stored = resetCodes.get(kkNumber);
  if (!stored) return { valid: false, error: 'No reset code requested' };

  const attempts = attemptCounts.get(kkNumber) || { count: 0, lockedUntil: 0 };

  if (attempts.lockedUntil > Date.now()) {
    const remaining = Math.ceil((attempts.lockedUntil - Date.now()) / 60000);
    return { valid: false, error: `Too many attempts. Try again in ${remaining} minutes.` };
  }

  if (Date.now() > stored.expiresAt) {
    resetCodes.delete(kkNumber);
    attemptCounts.delete(kkNumber);
    return { valid: false, error: 'Reset code expired' };
  }

  if (stored.code !== code) {
    attempts.count++;
    if (attempts.count >= MAX_ATTEMPTS) {
      attempts.lockedUntil = Date.now() + LOCKOUT_DURATION;
      attempts.count = 0;
    }
    attemptCounts.set(kkNumber, attempts);
    return { valid: false, error: 'Invalid reset code' };
  }

  return { valid: true };
}

function consumeCode(kkNumber) {
  resetCodes.delete(kkNumber);
  attemptCounts.delete(kkNumber);
}

module.exports = { setCode, verifyCode, consumeCode };
