const request = require('supertest');
const { PrismaClient } = require('@prisma/client');
const { hashPassword } = require('../src/utils/password');
const app = require('../src/app');

const prisma = new PrismaClient();

let superToken;
let adminToken;
let profileId;

const patientKK = '3280' + String(Date.now()).padStart(12, '0').slice(-12);
const superKK = '3281' + String(Date.now() + 1).padStart(12, '0').slice(-12);
const adminKK = '3282' + String(Date.now() + 2).padStart(12, '0').slice(-12);
const superUsername = 'testsuper' + String(Date.now()).slice(-9);
const adminUsername = 'testadmpr' + String(Date.now()).slice(-9);
const testNIK = '8890' + String(Date.now() + 3).padStart(12, '0').slice(-12);

describe('GET /admin/profiles/:id (single profile detail)', () => {
  beforeAll(async () => {
    const hashedPassword = await hashPassword('test123');

    await prisma.user.create({
      data: {
        kkNumber: superKK,
        username: superUsername,
        responsibleName: 'Test Superadmin',
        password: hashedPassword,
        role: 'SUPERADMIN',
        phone: '08123456701',
      },
    });
    // Region-less ADMIN: must fail closed (404) on any profile.
    await prisma.user.create({
      data: {
        kkNumber: adminKK,
        username: adminUsername,
        responsibleName: 'Test Regionless Admin',
        password: hashedPassword,
        role: 'ADMIN',
        phone: '08123456702',
      },
    });

    const loginSuper = await request(app)
      .post('/api/v1/auth/login')
      .send({ identifier: superUsername, password: 'test123' });
    superToken = loginSuper.body.data.token;

    const loginAdmin = await request(app)
      .post('/api/v1/auth/login')
      .send({ identifier: adminUsername, password: 'test123' });
    adminToken = loginAdmin.body.data.token;

    await request(app)
      .post('/api/v1/auth/register')
      .send({ kkNumber: patientKK, responsibleName: 'Profile Detail Patient', password: 'test123', phone: '08123456703' });

    const loginPatient = await request(app)
      .post('/api/v1/auth/login')
      .send({ kkNumber: patientKK, password: 'test123' });

    const profile = await request(app)
      .post('/api/v1/profiles')
      .set('Authorization', `Bearer ${loginPatient.body.data.token}`)
      .send({ name: 'Detail Test Profile', nik: testNIK, gender: 'wanita', birthDate: '1985-01-01' });
    profileId = profile.body.data.id;
  });

  afterAll(async () => {
    const users = await prisma.user.findMany({
      where: { kkNumber: { in: [patientKK, superKK, adminKK] } },
      select: { id: true },
    });
    const userIds = users.map((u) => u.id);
    const profiles = await prisma.familyProfile.findMany({ where: { userId: { in: userIds } }, select: { id: true } });
    const profileIds = profiles.map((p) => p.id);

    if (profileIds.length > 0) {
      await prisma.healthMetric.deleteMany({ where: { profileId: { in: profileIds } } });
      await prisma.medicalScreening.deleteMany({ where: { profileId: { in: profileIds } } });
    }
    if (userIds.length > 0) {
      await prisma.notification.deleteMany({ where: { userId: { in: userIds } } });
      await prisma.familyProfile.deleteMany({ where: { userId: { in: userIds } } });
    }
    await prisma.user.deleteMany({ where: { kkNumber: { in: [patientKK, superKK, adminKK] } } });
    await prisma.$disconnect();
  });

  it('returns a single profile by familyProfile id', async () => {
    const res = await request(app)
      .get(`/api/v1/admin/profiles/${profileId}`)
      .set('Authorization', `Bearer ${superToken}`);

    expect(res.status).toBe(200);
    expect(res.body.data.id).toBe(profileId);
    expect(res.body.data.name).toBe('Detail Test Profile');
    expect(res.body.data.familyName).toBe('Profile Detail Patient');
    expect(Array.isArray(res.body.data.screenings)).toBe(true);
    expect(Array.isArray(res.body.data.metrics)).toBe(true);
  });

  it('404s for an unknown profile id', async () => {
    const res = await request(app)
      .get('/api/v1/admin/profiles/00000000-0000-0000-0000-000000000000')
      .set('Authorization', `Bearer ${superToken}`);
    expect(res.status).toBe(404);
  });

  it('fails closed (404) for a region-less ADMIN', async () => {
    const res = await request(app)
      .get(`/api/v1/admin/profiles/${profileId}`)
      .set('Authorization', `Bearer ${adminToken}`);
    expect(res.status).toBe(404);
  });
});
