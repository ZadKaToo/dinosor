const jwt = require('jsonwebtoken');

const verifyToken = (req, res, next) => {
  const authHeader = req.headers['authorization'];
  const token = authHeader && authHeader.split(' ')[1]; // ดึงค่า Token ออกมาจาก Header

  if (!token) {
    return res.status(401).json({ error: 'กรุณาเข้าสู่ระบบก่อนใช้งาน' });
  }

  try {
    const decoded = jwt.verify(token, process.env.JWT_SECRET);
    req.user = decoded; // เก็บข้อมูล user ไว้ใช้ในขั้นตอนถัดไป
    next(); // ผ่านด่านได้
  } catch (error) {
    res.status(403).json({ error: 'Token ไม่ถูกต้องหรือหมดอายุ' });
  }
};

module.exports = verifyToken;