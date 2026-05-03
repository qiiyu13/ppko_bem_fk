const WebSocket = require('ws');
const http = require('http');
const app = require('../src/app');
const { initWebSocketServer } = require('../src/websocket');
const { PrismaClient } = require('@prisma/client');
const request = require('supertest');

const prisma = new PrismaClient();
let server;
let wsUrl;
let authToken;

beforeAll(async () => {
  server = http.createServer(app);
  initWebSocketServer(server);
  await new Promise((resolve) => server.listen(0, resolve));
  const port = server.address().port;
  wsUrl = `ws://localhost:${port}/ws`;

  const res = await request(app)
    .post('/api/v1/auth/login')
    .send({ kkNumber: '3275000000000003', password: 'patient123' });
  authToken = res.body.data.token;
});

afterAll(async () => {
  await prisma.$disconnect();
  server.close();
});

test('WebSocket connects and authenticates with token', (done) => {
  const ws = new WebSocket(`${wsUrl}?token=${authToken}`);

  ws.on('message', (data) => {
    const message = JSON.parse(data.toString());
    if (message.event === 'authenticated') {
      expect(message.data.userId).toBeDefined();
      ws.close();
      done();
    }
  });
});

test('WebSocket rejects invalid token', (done) => {
  const ws = new WebSocket(`${wsUrl}?token=invalid`);

  ws.on('message', (data) => {
    const message = JSON.parse(data.toString());
    if (message.event === 'error') {
      expect(message.data.message).toBe('Authentication failed');
      ws.close();
      done();
    }
  });
});
