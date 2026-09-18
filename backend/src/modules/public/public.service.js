const jwt = require('jsonwebtoken');
const config = require('../../config');
const { profileQrPayload, toBrandedDataUrl } = require('../../utils/qr');
const pendingCredentials = require('../admin/pendingCredentials');

const prisma = require('../../utils/prisma');

// Verifies the long-lived "view your account QR again" link minted by
// admin/kiosk.service.js. Deliberately not run through utils/jwt.js's
// verifyToken (auth tokens) - this token carries no userId/role, only a
// profileId + purpose, so it can never be mistaken for a login session even
// if someone pasted it into the Authorization header.
const getProfileByViewToken = async (token) => {
  let decoded;
  try {
    decoded = jwt.verify(token, config.jwtSecret);
  } catch {
    throw Object.assign(new Error('Invalid or expired link'), { statusCode: 400 });
  }
  if (decoded.purpose !== 'profile_view' || !decoded.profileId) {
    throw Object.assign(new Error('Invalid link'), { statusCode: 400 });
  }

  const profile = await prisma.familyProfile.findFirst({
    where: { id: decoded.profileId, mergedIntoId: null },
    select: { id: true, name: true, nik: true, user: { select: { kkNumber: true, username: true } } },
  });
  if (!profile) throw Object.assign(new Error('Account not found'), { statusCode: 404 });

  return {
    name: profile.name,
    nik: profile.nik,
    kkNumber: profile.user.kkNumber,
    username: profile.user.username,
    // Only present the first time anyone opens this link - see
    // pendingCredentials.js. null on every visit after that.
    password: pendingCredentials.consume(profile.id),
    qrDataUrl: await toBrandedDataUrl(profileQrPayload(profile)),
  };
};

module.exports = { getProfileByViewToken };
