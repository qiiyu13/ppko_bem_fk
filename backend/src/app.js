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

// Behind nginx/Cloudflare: trust the first proxy hop so req.ip resolves to the
// real client (X-Forwarded-For), not the upstream socket. Without this every
// request shares one rate-limit bucket — the whole app locks out after 200 req.
app.set('trust proxy', 1);

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
// Mounted BEFORE the rate limiter: image-heavy screens (avatar lists) must not
// burn the API request budget.
app.use('/uploads', express.static(path.resolve(__dirname, '../uploads'), {
  maxAge: '1y',
  immutable: true,
}));

// Rate limit scoped to the API only — not static assets or WebSocket upgrades.
const apiLimiter = rateLimit({
  windowMs: 15 * 60 * 1000,
  max: 200,
  standardHeaders: true,
  legacyHeaders: false,
});

// Liveness probe — no DB, no rate limit, tiny body. Clients hit this to confirm
// real internet reachability (not just a live network interface) before trusting
// connectivity state. Must stay cheap and ahead of the rate limiter.
app.get('/health', (req, res) => res.status(200).json({ status: 'ok' }));

// Routes
app.use('/api/v1', apiLimiter, routes);

// Error handling
app.use(notFound);
app.use(errorHandler);

module.exports = app;
