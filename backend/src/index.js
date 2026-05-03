const http = require('http');
const app = require('./app');
const config = require('./config');
const { initWebSocketServer } = require('./websocket');
const prisma = require('./utils/prisma');

const server = http.createServer(app);
initWebSocketServer(server);

server.listen(config.port, () => {
  console.log(`Server running on port ${config.port}`);
  console.log(`WebSocket available at ws://localhost:${config.port}/ws`);
});

// Graceful shutdown
const shutdown = async (signal) => {
  console.log(`\n${signal} received. Shutting down gracefully...`);
  server.close(async () => {
    await prisma.$disconnect();
    console.log('Database disconnected. Server stopped.');
    process.exit(0);
  });
};

process.on('SIGTERM', () => shutdown('SIGTERM'));
process.on('SIGINT', () => shutdown('SIGINT'));
