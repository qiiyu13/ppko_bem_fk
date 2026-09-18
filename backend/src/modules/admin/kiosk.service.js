const crypto = require('crypto');
const jwt = require('jsonwebtoken');
const config = require('../../config');
const { hashPassword } = require('../../utils/password');
const { profileQrPayload } = require('../../utils/qr');
const pendingCredentials = require('./pendingCredentials');

const prisma = require('../../utils/prisma');

// Long-lived: this is the "scan again later" link on a printed slip or the
// patient's own phone, not a login session - it only ever reveals the public
// QR-scan payload (utils/qr.js), never the password.
const PROFILE_VIEW_TOKEN_EXPIRES_IN = '2y';

const randomKkNumber = () => Array.from({ length: 16 }, () => Math.floor(Math.random() * 10)).join('');

const slugifyName = (name) => (
  name
    .toLowerCase()
    .normalize('NFD').replace(/[\u0300-\u036f]/g, '')
    .replace(/[^a-z0-9]+/g, '_')
    .replace(/^_+|_+$/g, '')
    .slice(0, 40)
) || 'pasien';

// 8 URL-safe characters - easy enough to hand-copy onto a paper slip.
const randomPassword = () => crypto.randomBytes(6).toString('base64url');

const uniqueKkNumber = async () => {
  for (let i = 0; i < 10; i++) {
    const candidate = randomKkNumber();
    if (!(await prisma.user.findUnique({ where: { kkNumber: candidate } }))) return candidate;
  }
  throw new Error('Could not generate a unique KK number');
};

// Base slug first (closest to "login with your name"); on collision append a
// random 4-digit suffix rather than an incrementing counter, so a burst of
// walk-ins with the same name at one event can't be enumerated from a shared
// counter.
const uniqueUsername = async (name) => {
  const base = slugifyName(name);
  for (let i = 0; i < 10; i++) {
    const candidate = i === 0 ? base : `${base}${Math.floor(1000 + Math.random() * 9000)}`;
    if (!(await prisma.user.findUnique({ where: { username: candidate } }))) return candidate;
  }
  throw new Error('Could not generate a unique username');
};

const generateProfileViewToken = (profileId) =>
  jwt.sign({ profileId, purpose: 'profile_view' }, config.jwtSecret, { expiresIn: PROFILE_VIEW_TOKEN_EXPIRES_IN });

// Walk-in registration for someone who shows up at a screening event with an
// ID card: staff types the six fields off the card, we mint a fresh
// KK-keyed account plus a name-based username/password fallback (for anyone
// who comes back without the printed QR - no ID required), and hand back a QR
// in the same {profileId,name,nik} shape the app's own QR dialog/scanner
// already speak (widgets/profile_qr_dialog.dart, screens/admin/qr_scanner_screen.dart).
const registerWalkIn = async (data) => {
  if (data.nik) {
    const nikTaken = await prisma.familyProfile.findFirst({ where: { nik: data.nik, mergedIntoId: null } });
    if (nikTaken) throw Object.assign(new Error('NIK is already registered'), { statusCode: 409 });
  }

  const kkNumber = await uniqueKkNumber();
  const username = await uniqueUsername(data.name);
  const password = randomPassword();
  const hashedPassword = await hashPassword(password);

  const { profile } = await prisma.$transaction(async (tx) => {
    const user = await tx.user.create({
      data: {
        kkNumber,
        username,
        password: hashedPassword,
        responsibleName: data.name,
        role: 'PATIENT',
      },
    });
    const profile = await tx.familyProfile.create({
      data: {
        userId: user.id,
        name: data.name,
        nik: data.nik || null,
        gender: data.gender,
        occupation: data.occupation || null,
        income: data.income != null && data.income !== '' ? parseFloat(data.income) : null,
        bloodType: data.bloodType || null,
        address: data.address || null,
      },
    });
    return { user, profile };
  });

  // Handed out at most once, to whichever phone scans the QR first - see
  // pendingCredentials.js for why this isn't just embedded in the view token.
  pendingCredentials.stash(profile.id, password);

  return {
    kkNumber,
    username,
    password,
    profile: { id: profile.id, name: profile.name, nik: profile.nik },
    qrPayload: profileQrPayload(profile),
    viewToken: generateProfileViewToken(profile.id),
  };
};

module.exports = { registerWalkIn, generateProfileViewToken };
