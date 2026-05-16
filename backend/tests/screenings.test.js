const request = require('supertest');
const { PrismaClient } = require('@prisma/client');
const { hashPassword } = require('../src/utils/password');
const app = require('../src/app');

const prisma = new PrismaClient();

let patientToken;
let adminToken;
let profileId;

const testKK = '3275' + String(Date.now()).padStart(12, '0').slice(-12);
const adminKK = '3276' + String(Date.now() + 1).padStart(12, '0').slice(-12);

describe('Screening → Health Metrics Cascade', () => {
  beforeAll(async () => {
    const hashedPassword = await hashPassword('test123');

    const admin = await prisma.user.create({
      data: {
        kkNumber: adminKK,
        responsibleName: 'Test Admin',
        password: hashedPassword,
        role: 'ADMIN',
        phone: '08123456700',
      },
    });

    const loginAdmin = await request(app)
      .post('/api/v1/auth/login')
      .send({ kkNumber: adminKK, password: 'test123' });
    adminToken = loginAdmin.body.data.token;

    await request(app)
      .post('/api/v1/auth/register')
      .send({ kkNumber: testKK, responsibleName: 'Screening Test Patient', password: 'test123', phone: '08123456799' });

    const loginPatient = await request(app)
      .post('/api/v1/auth/login')
      .send({ kkNumber: testKK, password: 'test123' });
    patientToken = loginPatient.body.data.token;

    const profile = await request(app)
      .post('/api/v1/profiles')
      .set('Authorization', `Bearer ${patientToken}`)
      .send({ name: 'Test Profile', nik: '888777555', gender: 'pria', birthDate: '1990-05-01' });
    profileId = profile.body.data.id;
  });

  afterAll(async () => {
    const testUser = await prisma.user.findUnique({ where: { kkNumber: testKK } });
    const adminUser = await prisma.user.findUnique({ where: { kkNumber: adminKK } });

    const testUserIds = [testUser, adminUser].filter(Boolean).map((u) => u.id);

    const profiles = await prisma.familyProfile.findMany({ where: { userId: { in: testUserIds } }, select: { id: true } });
    const profileIds = profiles.map((p) => p.id);

    if (profileIds.length > 0) {
      await prisma.healthMetric.deleteMany({ where: { profileId: { in: profileIds } } });
      await prisma.medicalScreening.deleteMany({ where: { profileId: { in: profileIds } } });
    }
    if (testUserIds.length > 0) {
      await prisma.medicalScreening.deleteMany({ where: { screenedBy: { in: testUserIds } } });
      await prisma.familyProfile.deleteMany({ where: { userId: { in: testUserIds } } });
    }
    await prisma.user.deleteMany({
      where: { kkNumber: { in: [testKK, adminKK] } },
    });
    await prisma.$disconnect();
  });

  it('should auto-create health_metrics when a screening is created', async () => {
    const screeningRes = await request(app)
      .post('/api/v1/screenings')
      .set('Authorization', `Bearer ${adminToken}`)
      .send({
        profileId,
        systolic: 130,
        diastolic: 85,
        bloodSugar: 110,
        cholesterol: 190,
        uricAcid: 5.5,
        height: 170,
        weight: 70,
        screeningAt: new Date().toISOString(),
      });

    expect(screeningRes.status).toBe(201);
    expect(screeningRes.body.success).toBe(true);
    const screeningId = screeningRes.body.data.id;
    expect(screeningId).toBeDefined();

    const metricsRes = await request(app)
      .get(`/api/v1/metrics/latest?profileId=${profileId}`)
      .set('Authorization', `Bearer ${patientToken}`);

    expect(metricsRes.status).toBe(200);
    expect(metricsRes.body.success).toBe(true);

    const latestMetrics = metricsRes.body.data;
    expect(latestMetrics.length).toBeGreaterThanOrEqual(4);

    const byType = {};
    for (const m of latestMetrics) {
      byType[m.type] = m;
    }

    expect(byType['blood_pressure']).toBeDefined();
    expect(byType['blood_pressure'].value).toBe(130);
    expect(byType['blood_pressure'].secondaryValue).toBe(85);
    expect(byType['blood_pressure'].unit).toBe('mmHg');

    expect(byType['blood_sugar']).toBeDefined();
    expect(byType['blood_sugar'].value).toBe(110);
    expect(byType['blood_sugar'].unit).toBe('mg/dL');

    expect(byType['cholesterol']).toBeDefined();
    expect(byType['cholesterol'].value).toBe(190);
    expect(byType['cholesterol'].unit).toBe('mg/dL');

    expect(byType['uric_acid']).toBeDefined();
    expect(byType['uric_acid'].value).toBe(5.5);
    expect(byType['uric_acid'].unit).toBe('mg/dL');
  });

  it('should only create metrics for provided fields (partial screening)', async () => {
    const partialKK = '3277' + String(Date.now() + 2).padStart(12, '0').slice(-12);
    const hashedPassword = await hashPassword('test123');

    await prisma.user.create({
      data: {
        kkNumber: partialKK,
        responsibleName: 'Partial Test',
        password: hashedPassword,
        role: 'PATIENT',
        phone: '08123456600',
      },
    });

    const login = await request(app)
      .post('/api/v1/auth/login')
      .send({ kkNumber: partialKK, password: 'test123' });
    const partialToken = login.body.data.token;

    const prof = await request(app)
      .post('/api/v1/profiles')
      .set('Authorization', `Bearer ${partialToken}`)
      .send({ name: 'Partial Profile', nik: '888777444', gender: 'wanita', birthDate: '1992-03-15' });
    const partialProfileId = prof.body.data.id;

    const screeningRes = await request(app)
      .post('/api/v1/screenings')
      .set('Authorization', `Bearer ${adminToken}`)
      .send({
        profileId: partialProfileId,
        systolic: 120,
        diastolic: 80,
        height: 160,
        weight: 55,
        screeningAt: new Date().toISOString(),
      });

    expect(screeningRes.status).toBe(201);

    const metricsRes = await request(app)
      .get(`/api/v1/metrics/latest?profileId=${partialProfileId}`)
      .set('Authorization', `Bearer ${partialToken}`);

    const latestMetrics = metricsRes.body.data;
    const types = latestMetrics.map((m) => m.type);

    expect(types).toContain('blood_pressure');
    expect(types).not.toContain('blood_sugar');
    expect(types).not.toContain('cholesterol');
    expect(types).not.toContain('uric_acid');

    const partialUser = await prisma.user.findUnique({ where: { kkNumber: partialKK } });
    if (partialUser) {
      const partialProfiles = await prisma.familyProfile.findMany({ where: { userId: partialUser.id }, select: { id: true } });
      const partialProfileIds = partialProfiles.map((p) => p.id);
      if (partialProfileIds.length > 0) {
        await prisma.healthMetric.deleteMany({ where: { profileId: { in: partialProfileIds } } });
        await prisma.medicalScreening.deleteMany({ where: { profileId: { in: partialProfileIds } } });
      }
      await prisma.familyProfile.deleteMany({ where: { userId: partialUser.id } });
    }
    await prisma.user.deleteMany({ where: { kkNumber: partialKK } });
  });
});
