const success = (res, data = null, message = 'Success', statusCode = 200) => {
  return res.status(statusCode).json({ success: true, data, message });
};

const error = (res, message = 'Internal Server Error', statusCode = 500, code = 'INTERNAL_ERROR') => {
  return res.status(statusCode).json({ success: false, error: { code, message } });
};

const paginated = (res, data, total, page, limit, extras = {}) => {
  return res.status(200).json({
    success: true,
    data,
    meta: { total, page, limit, totalPages: Math.ceil(total / limit), ...extras },
  });
};

module.exports = { success, error, paginated };
