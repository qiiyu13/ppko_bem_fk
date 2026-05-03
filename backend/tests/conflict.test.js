const request = require('supertest');
const app = require('../src/app');
const { PrismaClient } = require('@prisma/client');

const prisma = new PrismaClient();

let authToken;
let profileId;
let profileUpdatedAt;

describe('Optimistic Locking / Conflict Detection', () => {
  beforeAll(async () => {
    // Login as patient
    const loginRes = await request(app)
      .post('/api/v1/auth/login')
      .send({ kkNumber: '3275000000000003', password: 'patient123' });
    authToken = loginRes.body.data.token;

    // Create a profile
    const profileRes = await request(app)
      .post('/api/v1/profiles')
      .set('Authorization', `Bearer ${authToken}`)
      .send({
        name: 'Test Profile',
        nik: '1234567890123456',
        gender: 'pria',
        birthDate: '1990-01-01T00:00:00Z',
      });
    profileId = profileRes.body.data.id;
    profileUpdatedAt = profileRes.body.data.updatedAt;
  });

  afterAll(async () => {
    // Cleanup: delete the test profile
    if (profileId) {
      await prisma.familyProfile.deleteMany({ where: { nik: '1234567890123456' } });
    }
    await prisma.$disconnect();
  });

  test('PUT /profiles/:id without updatedAt returns 400', async () => {
    const res = await request(app)
      .put(`/api/v1/profiles/${profileId}`)
      .set('Authorization', `Bearer ${authToken}`)
      .send({ name: 'New Name' });

    expect(res.statusCode).toBe(400);
    expect(res.body.error.code).toBe('VALIDATION_ERROR');
  });

  test('PUT /profiles/:id with stale updatedAt returns 409 CONFLICT', async () => {
    // First, update the profile on the server
    await request(app)
      .put(`/api/v1/profiles/${profileId}`)
      .set('Authorization', `Bearer ${authToken}`)
      .send({
        name: 'Server Updated Name',
        updatedAt: profileUpdatedAt,
      });

    // Now try to update with the old updatedAt
    const res = await request(app)
      .put(`/api/v1/profiles/${profileId}`)
      .set('Authorization', `Bearer ${authToken}`)
      .send({
        name: 'Client Stale Name',
        updatedAt: profileUpdatedAt,
      });

    expect(res.statusCode).toBe(409);
    expect(res.body.error.code).toBe('CONFLICT');
    expect(res.body.data).toBeDefined();
    expect(res.body.data.name).toBe('Server Updated Name');
  });

  test('PUT /profiles/:id with current updatedAt succeeds', async () => {
    // Fetch current state
    const getRes = await request(app)
      .get(`/api/v1/profiles/${profileId}`)
      .set('Authorization', `Bearer ${authToken}`);

    const currentUpdatedAt = getRes.body.data.updatedAt;

    const res = await request(app)
      .put(`/api/v1/profiles/${profileId}`)
      .set('Authorization', `Bearer ${authToken}`)
      .send({
        name: 'Final Name',
        updatedAt: currentUpdatedAt,
      });

    expect(res.statusCode).toBe(200);
    expect(res.body.data.name).toBe('Final Name');
  });

  test('DELETE /profiles/:id without updatedAt returns 400', async () => {
    const res = await request(app)
      .delete(`/api/v1/profiles/${profileId}`)
      .set('Authorization', `Bearer ${authToken}`);

    expect(res.statusCode).toBe(400);
    expect(res.body.error.code).toBe('VALIDATION_ERROR');
  });

  test('DELETE /profiles/:id with stale updatedAt returns 409 CONFLICT', async () => {
    const res = await request(app)
      .delete(`/api/v1/profiles/${profileId}`)
      .set('Authorization', `Bearer ${authToken}`)
      .send({ updatedAt: profileUpdatedAt });

    expect(res.statusCode).toBe(409);
    expect(res.body.error.code).toBe('CONFLICT');
  });
});
