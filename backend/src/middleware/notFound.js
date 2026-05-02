const { error } = require('../utils/response');

const notFound = (req, res) => {
  return error(res, `Route ${req.originalUrl} not found`, 404, 'NOT_FOUND');
};

module.exports = notFound;
