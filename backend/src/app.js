const express = require('express');
const cors = require('cors');
const helmet = require('helmet');
const compression = require('compression');
const morgan = require('morgan');
const rateLimit = require('express-rate-limit');
const path = require('path');
const config = require('./config');
const routes = require('./routes');
const errorHandler = require('./middleware/errorHandler');
const notFound = require('./middleware/notFound');

const app = express();

// Security
app.use(helmet());
app.use(compression());
if (config.nodeEnv === 'production') {
  app.use((req, res, next) => {
    if (req.headers['x-forwarded-proto'] !== 'https') {
      return res.redirect(301, `https://${req.headers.host}${req.url}`);
    }
    next();
  });
}
if (config.nodeEnv === 'production' && config.corsOrigin === '*') {
  console.error('FATAL: CORS_ORIGIN cannot be "*" in production. Set CORS_ORIGIN environment variable to your app domain.');
  process.exit(1);
}
app.use(cors({
  origin: config.corsOrigin,
  credentials: true,
}));
app.use(rateLimit({
  windowMs: 15 * 60 * 1000,
  max: 200,
  standardHeaders: true,
  legacyHeaders: false,
}));

// Body parsing
app.use(express.json({ limit: '1mb' }));
app.use(express.urlencoded({ extended: true, limit: '1mb' }));

// Logging
if (config.nodeEnv === 'production') {
  app.use(morgan('combined'));
} else {
  app.use(morgan('dev'));
}

// Static file serving. Upload filenames are unique per upload, so content is
// immutable per URL — cache aggressively to avoid revalidation round-trips.
app.use('/uploads', express.static(path.resolve(__dirname, '../uploads'), {
  maxAge: '1y',
  immutable: true,
}));

// Routes
app.use('/api/v1', routes);

// Error handling
app.use(notFound);
app.use(errorHandler);

module.exports = app;
