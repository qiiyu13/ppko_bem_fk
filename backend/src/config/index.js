require('dotenv').config();

const jwtSecret = process.env.JWT_SECRET || 'dev-secret-change-in-production';

const config = {
  port: process.env.PORT || 3000,
  databaseUrl: process.env.DATABASE_URL,
  jwtSecret,
  jwtExpiresIn: process.env.JWT_EXPIRES_IN || '7d',
  jwtIssuer: process.env.JWT_ISSUER || 'mediku-api',
  jwtAudience: process.env.JWT_AUDIENCE || 'mediku-app',
  // Absolute session lifetime (seconds). A token can be refreshed within its
  // sliding 7d window indefinitely; this caps the total age since first login so
  // a continuously-refreshed session still forces re-auth eventually. Default 30d.
  maxSessionAge: parseInt(process.env.MAX_SESSION_AGE_SECONDS || '2592000', 10),
  corsOrigin: process.env.CORS_ORIGIN || '*',
  nodeEnv: process.env.NODE_ENV || 'development',
};

// Hard-fail in production if critical environment variables are missing
if (config.nodeEnv === 'production') {
  if (!process.env.JWT_SECRET) {
    console.error('FATAL: JWT_SECRET environment variable is required in production');
    process.exit(1);
  }
  if (!process.env.DATABASE_URL) {
    console.error('FATAL: DATABASE_URL environment variable is required in production');
    process.exit(1);
  }
}

module.exports = config;
