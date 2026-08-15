const ApiError = require('../utils/ApiError');

function errorHandler(err, req, res, next) { // eslint-disable-line no-unused-vars
  if (err instanceof ApiError) {
    return res.status(err.statusCode).json({ error: err.message });
  }

  // Postgres unique_violation
  if (err.code === '23505') {
    return res.status(409).json({ error: 'ข้อมูลนี้มีอยู่แล้วในระบบ' });
  }

  // Postgres foreign_key_violation / not-null etc.
  if (err.code && err.code.startsWith('23')) {
    return res.status(400).json({ error: 'ข้อมูลที่ส่งมาไม่ถูกต้อง' });
  }

  console.error(err);
  res.status(500).json({ error: 'Internal server error' });
}

module.exports = errorHandler;
