const blacklistedTokens = new Set();

function blacklistToken(token, expiresAt) {
  blacklistedTokens.add(token);
  const ttl = expiresAt - Date.now();
  if (ttl > 0) setTimeout(() => blacklistedTokens.delete(token), ttl);
}

function isBlacklisted(token) {
  return blacklistedTokens.has(token);
}

module.exports = { blacklistToken, isBlacklisted };
