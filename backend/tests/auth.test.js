const request = require('supertest');
const app = require('../src/app');

let authToken;
const testKkNumber = '1234567890' + Date.now().toString().slice(-6);

describe('Auth Endpoints', () => {
  afterAll(async () => {
    // Cleanup: no DB cleanup needed for integration tests
  });

  it('should register a new user', async () => {
    const res = await request(app)
      .post('/api/v1/auth/register')
      .send({ kkNumber: testKkNumber, responsibleName: 'Test User', password: 'test123', phone: '081234567890' });
    expect(res.status).toBe(201);
    expect(res.body.success).toBe(true);
    expect(res.body.data.token).toBeDefined();
    expect(res.body.data.user.role).toBe('PATIENT');
  });

  it('should reject duplicate KK number', async () => {
    const res = await request(app)
      .post('/api/v1/auth/register')
      .send({ kkNumber: testKkNumber, responsibleName: 'Test User 2', password: 'test123' });
    expect(res.status).toBe(409);
    expect(res.body.success).toBe(false);
    expect(res.body.error.code).toBe('CONFLICT');
  });

  it('should reject invalid KK number (not 16 digits)', async () => {
    const res = await request(app)
      .post('/api/v1/auth/register')
      .send({ kkNumber: '123', responsibleName: 'Test', password: 'test123' });
    expect(res.status).toBe(400);
    expect(res.body.success).toBe(false);
  });

  it('should login with valid credentials', async () => {
    const res = await request(app)
      .post('/api/v1/auth/login')
      .send({ kkNumber: testKkNumber, password: 'test123' });
    expect(res.status).toBe(200);
    expect(res.body.success).toBe(true);
    expect(res.body.data.token).toBeDefined();
    authToken = res.body.data.token;
  });

  it('should reject invalid credentials', async () => {
    const res = await request(app)
      .post('/api/v1/auth/login')
      .send({ kkNumber: testKkNumber, password: 'wrongpassword' });
    expect(res.status).toBe(401);
    expect(res.body.success).toBe(false);
    expect(res.body.error.code).toBe('INVALID_CREDENTIALS');
  });

  it('should get current user with token', async () => {
    const res = await request(app)
      .get('/api/v1/auth/me')
      .set('Authorization', `Bearer ${authToken}`);
    expect(res.status).toBe(200);
    expect(res.body.success).toBe(true);
    expect(res.body.data.kkNumber).toBe(testKkNumber);
  });

  it('should reject /me without token', async () => {
    const res = await request(app).get('/api/v1/auth/me');
    expect(res.status).toBe(401);
    expect(res.body.error.code).toBe('UNAUTHORIZED');
  });

  it('should reject /me with invalid token', async () => {
    const res = await request(app)
      .get('/api/v1/auth/me')
      .set('Authorization', 'Bearer invalidtoken');
    expect(res.status).toBe(401);
    expect(res.body.error.code).toBe('INVALID_TOKEN');
  });
});
