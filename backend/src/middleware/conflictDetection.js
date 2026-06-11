const prisma = require('../utils/prisma');

/**
 * Optimistic locking middleware.
 * Expects req.body.updatedAt (ISO string) for PUT/DELETE requests.
 * Compares with the current record's updatedAt in the database.
 * If they differ, returns 409 CONFLICT with current server data.
 */
const conflictDetection = (modelName, idParam = 'id') => async (req, res, next) => {
  // Only apply to PUT and DELETE
  if (!['PUT', 'DELETE'].includes(req.method)) {
    return next();
  }

  const clientUpdatedAt = req.body?.updatedAt || req.query?.updatedAt;
  if (!clientUpdatedAt) {
    return res.status(400).json({
      success: false,
      error: {
        code: 'MISSING_UPDATED_AT',
        message: 'updatedAt is required for updates and deletes',
      },
    });
  }

  const id = req.params[idParam];
  if (!id) {
    return res.status(400).json({
      success: false,
      error: {
        code: 'MISSING_ID',
        message: 'Resource ID is required',
      },
    });
  }

  try {
    const record = await prisma[modelName].findUnique({ where: { id } });

    if (!record) {
      return res.status(404).json({
        success: false,
        error: {
          code: 'NOT_FOUND',
          message: 'Resource not found',
        },
      });
    }

    const serverUpdatedAt = record.updatedAt?.toISOString();
    const clientTime = new Date(clientUpdatedAt).toISOString();

    if (serverUpdatedAt !== clientTime) {
      // Do NOT echo the full row here: conflictDetection runs before the
      // controller's ownership check, so returning `record` would disclose any
      // row (another user's profile, a user's password hash, etc.) to any
      // authenticated caller who guesses an id and sends a mismatched
      // updatedAt. Return only the server timestamp; an owner can re-fetch the
      // current version through the normal (ownership-scoped) GET endpoint.
      return res.status(409).json({
        success: false,
        error: {
          code: 'CONFLICT',
          message: 'This record was modified by another user or device. Please review the current version.',
        },
        data: { id: record.id, updatedAt: record.updatedAt },
      });
    }

    // Attach record to req so controllers don't need to re-fetch
    req.existingRecord = record;
    next();
  } catch (err) {
    next(err);
  }
};

module.exports = conflictDetection;
