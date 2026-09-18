// Short-lived, in-memory-only holder for a walk-in account's plaintext
// password between kiosk creation and the first time the patient's own phone
// opens the QR-linked account page (public/my-account.html).
//
// Why not put the password in the view-link's JWT instead? A JWT is SIGNED,
// not ENCRYPTED - any payload placed in it is plainly base64-readable by
// anyone holding the link/QR image, forever, regardless of the token's
// `exp`. That would mean the password leaks permanently to anyone who ever
// sees the QR (a photo of the kiosk screen, a shared screenshot, ...).
// Keeping the password out of the token and handing it out at most once from
// server memory bounds the exposure to "whoever scans the QR first".
//
// SCALING CAVEAT (single-instance only, same as tokenBlacklist.js): this is
// per-process memory. Fine for the current single-instance deployment; a
// restart mid-event just falls back to the password the kiosk screen already
// showed staff once at creation time.
const pending = new Map(); // profileId -> { password, expiresAt }

const DEFAULT_TTL_MS = 24 * 60 * 60 * 1000; // clears itself even if never scanned

const stash = (profileId, password, ttlMs = DEFAULT_TTL_MS) => {
  pending.set(profileId, { password, expiresAt: Date.now() + ttlMs });
};

// One-time read: the first caller (whoever's phone hits the link first) gets
// the password, everyone after gets null.
const consume = (profileId) => {
  const entry = pending.get(profileId);
  pending.delete(profileId);
  if (!entry || entry.expiresAt <= Date.now()) return null;
  return entry.password;
};

module.exports = { stash, consume };
