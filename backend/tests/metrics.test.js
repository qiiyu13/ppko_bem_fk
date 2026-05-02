const request = require('supertest');
const app = require('../src/app');

let authToken;
let profileId;
const testKK = '3275' + String(Date.now() + 1).padStart(12, '0').slice(-12);

describe('Metrics Endpoints', () => {
  beforeAll(async () => {
    // Register, login, create profile
    await request(app)
      .post('/api/v1/auth/register')
      .send({ kkNumber: testKK, responsibleName: 'Metrics Test', password: 'test123', phone: '08123456789' });

    const login = await request(app)
      .post('/api/v1/auth/login')
      .send({ kkNumber: testKK, password: 'test123' });
    authToken = login.body.data.token;

    const profile = await request(app)
      .post('/api/v1/profiles')
      .set('Authorization', `Bearer ${authToken}`)
      .send({ name: 'Test Profile', nik: '888777666', gender: 'wanita', birthDate: '1985-01-01' });
    profileId = profile.body.data.id;
  });

  it('should create a health metric', async () => {
    const res = await request(app)
      .post('/api/v1/metrics')
      .set('Authorization', `Bearer ${authToken}`)
      .send({
        profileId,
        type: 'blood_pressure',
        value: 120,
        secondaryValue: 80,
        unit: 'mmHg',
        notes: 'Normal reading',
      });
    expect(res.status).toBe(201);
    expect(res.body.success).toBe(true);
    expect(res.body.data.value).toBe(120);
    expect(res.body.data.secondaryValue).toBe(80);
  });

  it('should list metrics for profile', async () => {
    const res = await request(app)
      .get(`/api/v1/metrics?profileId=${profileId}`)
      .set('Authorization', `Bearer ${authToken}`);
    expect(res.status).toBe(200);
    expect(res.body.success).toBe(true);
    expect(res.body.data.length).toBeGreaterThanOrEqual(1);
  });

  it('should get metric history by type', async () => {
    const res = await request(app)
      .get(`/api/v1/metrics/blood_pressure/history?profileId=${profileId}`)
      .set('Authorization', `Bearer ${authToken}`);
    expect(res.status).toBe(200);
    expect(res.body.success).toBe(true);
    expect(res.body.data[0].type).toBe('blood_pressure');
  });

  it('should get latest metrics', async () => {
    const res = await request(app)
      .get(`/api/v1/metrics/latest?profileId=${profileId}`)
      .set('Authorization', `Bearer ${authToken}`);
    expect(res.status).toBe(200);
    expect(res.body.success).toBe(true);
    expect(res.body.data.length).toBeGreaterThanOrEqual(1);
  });

  it('should reject metric creation without required fields', async () => {
    const res = await request(app)
      .post('/api/v1/metrics')
      .set('Authorization', `Bearer ${authToken}`)
      .send({ profileId, type: 'blood_sugar' });
    expect(res.status).toBe(400);
    expect(res.body.success).toBe(false);
  });

  it('should reject metrics for non-owned profile', async () => {
    const res = await request(app)
      .get('/api/v1/metrics?profileId=non-existent-id')
      .set('Authorization', `Bearer ${authToken}`);
    expect(res.status).toBe(404);
    expect(res.body.error.code).toBe('NOT_FOUND');
  });
});
