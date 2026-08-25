const express = require('express');
const cors = require('cors');
const helmet = require('helmet');
const morgan = require('morgan');
const rateLimit = require('express-rate-limit');
const path = require('path');
const config = require('./config');
const routes = require('./routes');
const { verifyToken } = require('./utils/jwt');
const errorHandler = require('./middleware/errorHandler');
const notFound = require('./middleware/notFound');

const app = express();

// Behind nginx/Cloudflare: trust the first proxy hop so req.ip resolves to the
// real client (X-Forwarded-For), not the upstream socket. Without this every
// request shares one rate-limit bucket — the whole app locks out after 200 req.
app.set('trust proxy', 1);

// Security
app.use(helmet());
// No in-process compression: nginx gzips proxied responses (gzip_proxied any),
// so compressing in Node would only burn event-loop CPU doing the same work.
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

// Request logging: dev only. In production nginx already writes access logs;
// a second per-request formatter on the event loop is pure overhead.
if (config.nodeEnv !== 'production') {
  app.use(morgan('dev'));
}

// Static file serving. Upload filenames are unique per upload, so content is
// immutable per URL — cache aggressively to avoid revalidation round-trips.
// Mounted BEFORE the rate limiter: image-heavy screens (avatar lists) must not
// burn the API request budget.
app.use('/uploads', express.static(path.resolve(__dirname, '../uploads'), {
  maxAge: '1y',
  immutable: true,
  setHeaders: (res, filePath) => {
    // Force download instead of an in-browser preview attempt for APKs
    // (e.g. QR-code install links) — no click-through needed.
    if (filePath.endsWith('.apk')) {
      res.setHeader('Content-Disposition', 'attachment');
    }
  },
}));

// Static site files (privacy policy required by Google Play, etc.). Served
// ahead of the rate limiter like /uploads — it is a legal page, not API traffic.
app.use(express.static(path.resolve(__dirname, '../public'), {
  maxAge: '1d',
  setHeaders: (res, filePath) => {
    if (filePath.endsWith('.html')) res.setHeader('Content-Type', 'text/html; charset=UTF-8');
  },
}));

// Rate limit scoped to the API only — not static assets or WebSocket upgrades.
// Keyed by user id when the request carries a valid token, not just req.ip:
// admins on the same campus NAT'd WiFi share one public IP, so IP-keying would
// collapse e.g. 20 concurrent admins into a single 200-req/15min bucket.
// This runs ahead of the real `authenticate` middleware, so it only peeks at
// the token (verify, no DB/blacklist check) — falls back to IP pre-login.
const apiLimiter = rateLimit({
  windowMs: 15 * 60 * 1000,
  max: 200,
  standardHeaders: true,
  legacyHeaders: false,
  keyGenerator: (req, res) => {
    const authHeader = req.headers.authorization;
    if (authHeader && authHeader.startsWith('Bearer ')) {
      try {
        const { userId } = verifyToken(authHeader.split(' ')[1]);
        if (userId) return `user:${userId}`;
      } catch {
        // fall through to IP-based key below
      }
    }
    return rateLimit.ipKeyGenerator(req, res);
  },
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
