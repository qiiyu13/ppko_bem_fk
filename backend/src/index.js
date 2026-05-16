const http = require('http');
const app = require('./app');
const config = require('./config');
const { initWebSocketServer } = require('./websocket');
const prisma = require('./utils/prisma');
const { initBlacklist, cleanupExpiredTokens } = require('./modules/auth/tokenBlacklist');
const logger = require('./utils/logger');

const server = http.createServer(app);
initWebSocketServer(server);

// Initialize token blacklist from database before accepting connections
initBlacklist().then(() => {
  server.listen(config.port, () => {
    logger.info(`Server running on port ${config.port} [${config.nodeEnv}]`);
    logger.info(`WebSocket available at ws://localhost:${config.port}/ws`);
  });
});

// Clean up expired blacklisted tokens every hour
setInterval(cleanupExpiredTokens, 60 * 60 * 1000);

// Graceful shutdown
const shutdown = async (signal) => {
  logger.info(`${signal} received. Shutting down gracefully...`);
  server.close(async () => {
    await prisma.$disconnect();
    logger.info('Database disconnected. Server stopped.');
    process.exit(0);
  });
};

process.on('SIGTERM', () => shutdown('SIGTERM'));
process.on('SIGINT', () => shutdown('SIGINT'));

