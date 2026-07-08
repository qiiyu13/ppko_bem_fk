const prisma = require('./prisma');

// A profile is accessible to a user if they're the owner or hold a
// ProfileLink to it (multi-account sharing, e.g. Sekolah Lansia org account
// + the lansia's own family account). Merged-away profiles are never
// accessible directly - callers should already be pointed at the canonical id.
const accessibleWhere = (userId) => ({
  mergedIntoId: null,
  OR: [{ userId }, { links: { some: { userId } } }],
});

const getAccessibleProfile = (id, userId) =>
  prisma.familyProfile.findFirst({ where: { id, ...accessibleWhere(userId) } });

module.exports = { accessibleWhere, getAccessibleProfile };
