const request = require('supertest');
const { PrismaClient } = require('@prisma/client');
const app = require('../src/app');

const prisma = new PrismaClient();

// Registrations sending "1", "01", and "001" for the same RW/RT must all land
// on one region row ("RW 01"), not mint zero-padding variants.
describe('RW/RT name normalization at registration', () => {
  const kk1 = '3283' + String(Date.now()).padStart(12, '0').slice(-12);
  const kk2 = '3284' + String(Date.now() + 1).padStart(12, '0').slice(-12);
  let villageId;

  beforeAll(async () => {
    const village = await prisma.region.create({
      data: { type: 'VILLAGE', name: 'Test Desa Norm ' + Date.now() },
    });
    villageId = village.id;
  });

  afterAll(async () => {
    await prisma.$disconnect();
  });

  it('collapses zero-padding variants onto one RW/RT row', async () => {
    const r1 = await request(app)
      .post('/api/v1/auth/register')
      .send({
        kkNumber: kk1, responsibleName: 'Norm One', password: 'test123',
        villageId, rwNumber: '1', rtNumber: '01',
      });
    expect(r1.status).toBe(201);

    const r2 = await request(app)
      .post('/api/v1/auth/register')
      .send({
        kkNumber: kk2, responsibleName: 'Norm Two', password: 'test123',
        villageId, rwNumber: '001', rtNumber: '1',
      });
    expect(r2.status).toBe(201);

    const rws = await prisma.region.findMany({
      where: { type: 'RW', parentId: villageId },
    });
    expect(rws).toHaveLength(1);
    expect(rws[0].name).toBe('RW 01');

    const rts = await prisma.region.findMany({
      where: { type: 'RT', parentId: rws[0].id },
    });
    expect(rts).toHaveLength(1);
    expect(rts[0].name).toBe('RT 01');
  });
});
