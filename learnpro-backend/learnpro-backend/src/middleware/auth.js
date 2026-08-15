const jwt = require('jsonwebtoken');
const ApiError = require('../utils/ApiError');

function auth(req, res, next) {
  const header = req.headers.authorization || '';
  const token = header.startsWith('Bearer ') ? header.slice(7) : null;

  if (!token) {
    return next(new ApiError(401, 'ไม่พบ token กรุณาเข้าสู่ระบบ'));
  }

  try {
    const payload = jwt.verify(token, process.env.JWT_SECRET);
    req.userId = payload.sub;
    next();
  } catch (err) {
    next(new ApiError(401, 'Token ไม่ถูกต้องหรือหมดอายุ'));
  }
}

module.exports = auth;
