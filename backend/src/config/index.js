require('dotenv').config();

const jwtSecret = process.env.JWT_SECRET || 'dev-secret-change-in-production';

const config = {
  port: process.env.PORT || 3000,
  databaseUrl: process.env.DATABASE_URL,
  jwtSecret,
  jwtExpiresIn: process.env.JWT_EXPIRES_IN || '7d',
  corsOrigin: process.env.CORS_ORIGIN || '*',
  nodeEnv: process.env.NODE_ENV || 'development',
};

if (!process.env.JWT_SECRET && config.nodeEnv === 'production') {
  console.error('FATAL: JWT_SECRET environment variable is required in production');
  process.exitCode = 1;
}

module.exports = config;
