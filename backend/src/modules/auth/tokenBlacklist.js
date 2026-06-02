const prisma = require('../../utils/prisma');
const logger = require('../../utils/logger');

// In-memory cache for fast lookups (populated from DB on startup).
// Map of token -> expiry epoch ms. Expiry is checked lazily on read instead of
// arming a setTimeout per token: a timer-per-token leaks both timer handles and
// retained token strings under high logout volume and never shrinks the heap.
//
// SCALING CAVEAT (single-instance only): this cache is per-process and is loaded
// from the DB only at startup. A logout on one instance is NOT visible to other
// instances, so revocation does not propagate horizontally. Before scaling out,
// move this to a shared store (e.g. Redis) or query the persisted
// `token_blacklist` row on the auth path.
const blacklistCache = new Map();

/**
 * Initialize the blacklist cache from the database.
 * Called once at server startup to populate the in-memory map.
 */
async function initBlacklist() {
  try {
    // Clean up expired tokens first
    await prisma.tokenBlacklist.deleteMany({
      where: { expiresAt: { lt: new Date() } },
    });

    // Load active blacklisted tokens into memory
    const tokens = await prisma.tokenBlacklist.findMany({
      select: { token: true, expiresAt: true },
    });

    for (const { token, expiresAt } of tokens) {
      blacklistCache.set(token, expiresAt.getTime());
    }

    logger.info(`Token blacklist initialized with ${tokens.length} active entries`);
  } catch (err) {
    logger.error({ err }, 'Failed to initialize token blacklist from database');
  }
}

/**
 * Blacklist a token (persist to DB + add to memory cache).
 * @param {string} token - The JWT token string
 * @param {number} expiresAtMs - Token expiry time in milliseconds (from decoded.exp * 1000)
 */
async function blacklistToken(token, expiresAtMs) {
  // Add to in-memory cache immediately for fast lookups
  blacklistCache.set(token, expiresAtMs);

  // Persist to database (fire-and-forget with error logging)
  try {
    await prisma.tokenBlacklist.create({
      data: { token, expiresAt: new Date(expiresAtMs) },
    });
  } catch (err) {
    // Ignore unique constraint violations (token already blacklisted)
    if (err.code !== 'P2002') {
      logger.error({ err }, 'Failed to persist blacklisted token');
    }
  }
}

/**
 * Check if a token is blacklisted.
 * O(1) Map lookup with lazy expiry: an entry past its expiry is evicted on
 * access and treated as not-blacklisted (the JWT itself is expired by then).
 * @param {string} token
 * @returns {boolean}
 */
function isBlacklisted(token) {
  const expiresAtMs = blacklistCache.get(token);
  if (expiresAtMs === undefined) return false;
  if (expiresAtMs <= Date.now()) {
    blacklistCache.delete(token);
    return false;
  }
  return true;
}

/**
 * Clean up expired tokens from the database and prune the in-memory map.
 * Should be called periodically (e.g., every hour).
 */
async function cleanupExpiredTokens() {
  const now = Date.now();
  for (const [token, expiresAtMs] of blacklistCache) {
    if (expiresAtMs <= now) blacklistCache.delete(token);
  }
  try {
    const result = await prisma.tokenBlacklist.deleteMany({
      where: { expiresAt: { lt: new Date() } },
    });
    if (result.count > 0) {
      logger.info(`Cleaned up ${result.count} expired blacklisted tokens`);
    }
  } catch (err) {
    logger.error({ err }, 'Failed to cleanup expired tokens');
  }
}

module.exports = { initBlacklist, blacklistToken, isBlacklisted, cleanupExpiredTokens };
