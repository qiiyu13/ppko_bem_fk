const { error } = require('../utils/response');
const config = require('../config');
const logger = require('../utils/logger');

const errorHandler = (err, req, res, next) => {
  logger.error({ err }, 'Unhandled error');

  // Prisma unique constraint violation
  if (err.code === 'P2002') {
    return error(res, 'Data already exists', 409, 'CONFLICT');
  }

  // Prisma not found
  if (err.code === 'P2025') {
    return error(res, 'Resource not found', 404, 'NOT_FOUND');
  }

  // Prisma foreign key violation
  if (err.code === 'P2003') {
    return error(res, 'Referenced resource not found', 400, 'FOREIGN_KEY_ERROR');
  }

  const message = config.nodeEnv === 'production'
    ? 'Internal server error'
    : (err.message || 'Internal Server Error');

  return error(res, message, 500, 'INTERNAL_ERROR');
};

module.exports = errorHandler;
