const bcrypt = require('bcrypt');

// Native bcrypt runs in the libuv threadpool (non-blocking) and is far faster
// than bcryptjs. Cost 10 is the OWASP-recommended default; existing cost-12
// hashes still verify because the cost is embedded in the hash string.
const SALT_ROUNDS = 10;

const hashPassword = async (password) => {
  return bcrypt.hash(password, SALT_ROUNDS);
};

const comparePassword = async (password, hash) => {
  return bcrypt.compare(password, hash);
};

module.exports = { hashPassword, comparePassword };
