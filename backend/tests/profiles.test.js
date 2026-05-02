const request = require('supertest');
const app = require('../src/app');

let authToken;
let profileId;
const testKK = '3275' + String(Date.now()).padStart(12, '0').slice(-12);

describe('Profiles Endpoints', () => {
  beforeAll(async () => {
    // Register and login
    await request(app)
      .post('/api/v1/auth/register')
      .send({ kkNumber: testKK, responsibleName: 'Profile Test', password: 'test123', phone: '08123456789' });

    const login = await request(app)
      .post('/api/v1/auth/login')
      .send({ kkNumber: testKK, password: 'test123' });
    authToken = login.body.data.token;
  });

  it('should create a family profile', async () => {
    const res = await request(app)
      .post('/api/v1/profiles')
      .set('Authorization', `Bearer ${authToken}`)
      .send({
        name: 'Budi Santoso',
        nik: '999888777',
        gender: 'pria',
        birthDate: '1985-05-15',
        height: 170,
        weight: 75,
        bloodType: 'O',
      });
    expect(res.status).toBe(201);
    expect(res.body.success).toBe(true);
    expect(res.body.data.name).toBe('Budi Santoso');
    profileId = res.body.data.id;
  });

  it('should list profiles', async () => {
    const res = await request(app)
      .get('/api/v1/profiles')
      .set('Authorization', `Bearer ${authToken}`);
    expect(res.status).toBe(200);
    expect(res.body.success).toBe(true);
    expect(res.body.data.length).toBeGreaterThanOrEqual(1);
  });

  it('should get single profile', async () => {
    const res = await request(app)
      .get(`/api/v1/profiles/${profileId}`)
      .set('Authorization', `Bearer ${authToken}`);
    expect(res.status).toBe(200);
    expect(res.body.data.id).toBe(profileId);
  });

  it('should update profile', async () => {
    const res = await request(app)
      .put(`/api/v1/profiles/${profileId}`)
      .set('Authorization', `Bearer ${authToken}`)
      .send({ name: 'Budi Updated', weight: 78 });
    expect(res.status).toBe(200);
    expect(res.body.data.name).toBe('Budi Updated');
    expect(res.body.data.weight).toBe(78);
  });

  it('should reject access without token', async () => {
    const res = await request(app).get('/api/v1/profiles');
    expect(res.status).toBe(401);
    expect(res.body.error.code).toBe('UNAUTHORIZED');
  });

  it('should return 404 for non-existent profile', async () => {
    const res = await request(app)
      .get('/api/v1/profiles/non-existent-id')
      .set('Authorization', `Bearer ${authToken}`);
    expect(res.status).toBe(404);
    expect(res.body.error.code).toBe('NOT_FOUND');
  });

  it('should delete profile', async () => {
    const res = await request(app)
      .delete(`/api/v1/profiles/${profileId}`)
      .set('Authorization', `Bearer ${authToken}`);
    expect(res.status).toBe(200);
    expect(res.body.data.message).toBe('Profile deleted successfully');
  });
});
