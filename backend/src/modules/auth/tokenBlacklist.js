const prisma = require('../../utils/prisma');
const logger = require('../../utils/logger');

// In-memory cache for fast lookups (populated from DB on startup)
const blacklistCache = new Set();

/**
 * Initialize the blacklist cache from the database.
 * Called once at server startup to populate the in-memory set.
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
      blacklistCache.add(token);
      // Schedule removal from memory cache when token expires
      const ttl = expiresAt.getTime() - Date.now();
      if (ttl > 0) {
        setTimeout(() => blacklistCache.delete(token), ttl);
      }
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
  const expiresAt = new Date(expiresAtMs);

  // Add to in-memory cache immediately for fast lookups
  blacklistCache.add(token);

  // Schedule removal from memory cache when token expires
  const ttl = expiresAtMs - Date.now();
  if (ttl > 0) {
    setTimeout(() => blacklistCache.delete(token), ttl);
  }

  // Persist to database (fire-and-forget with error logging)
  try {
    await prisma.tokenBlacklist.create({
      data: { token, expiresAt },
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
 * Uses the in-memory cache for O(1) lookup performance.
 * @param {string} token
 * @returns {boolean}
 */
function isBlacklisted(token) {
  return blacklistCache.has(token);
}

/**
 * Clean up expired tokens from the database.
 * Should be called periodically (e.g., every hour).
 */
async function cleanupExpiredTokens() {
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
