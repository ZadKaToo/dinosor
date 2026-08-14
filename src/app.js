const express = require('express');
const cors = require('cors');
const helmet = require('helmet'); 
const rateLimit = require('express-rate-limit');
const morgan = require('morgan'); // แนะนำให้ลงเพิ่ม (npm install morgan) เพื่อดู Log การยิง API
require('dotenv').config();

// ==========================================
// 1. นำเข้า Routes ทั้งหมด (Import Routes)
// ==========================================
const authRoutes = require('./routes/authRoutes');
const courseRoutes = require('./routes/courseRoutes');
const sideTabRoutes = require('./routes/sideTabRoutes'); // ปลดคอมเมนต์และใช้งานจริง

const app = express();

// ==========================================
// 2. ตั้งค่า Middlewares พื้นฐาน & ความปลอดภัย
// ==========================================
app.use(helmet()); // ซ่อน Header ป้องกันการโจมตี
app.use(cors()); // อนุญาตให้ Mobile App ข้ามโดเมนมาเรียก API ได้
app.use(express.json()); // ให้ API รับข้อมูลแบบ JSON ได้
app.use(morgan('dev')); // แสดง Log สวยๆ ใน Terminal เวลาแอปยิง API มา

// ป้องกันคนยิง API ถล่มเซิร์ฟเวอร์ (จำกัด 100 ครั้งต่อ 15 นาที ต่อ 1 IP)
const apiLimiter = rateLimit({
  windowMs: 15 * 60 * 1000, 
  max: 100,
  message: { error: 'คุณเรียกใช้งานบ่อยเกินไป กรุณารอสักครู่' }
});
app.use('/api/', apiLimiter);

// ==========================================
// 3. เชื่อมต่อ API Endpoints
// ==========================================
app.use('/api/auth', authRoutes);       // ระบบ Login, Register, เลือกอาชีพ
app.use('/api/courses', courseRoutes);  // ระบบหน้า Feed คอร์สเรียน
app.use('/api/sidetab', sideTabRoutes); // ระบบเมนูด้านข้าง (Profile, History, Saved, Settings)

// ==========================================
// 4. จัดการกรณีผู้ใช้ยิง API มาผิดเส้นทาง (404 Not Found)
// ==========================================
app.use((req, res, next) => {
  res.status(404).json({ error: 'ไม่พบเส้นทาง API นี้ (Route Not Found)' });
});

// ==========================================
// 5. จัดการ Error ระดับ Global (กันเซิร์ฟเวอร์พัง)
// ==========================================
app.use((err, req, res, next) => {
  console.error('[Server Error]:', err.stack); // พิมพ์ Error ลง Console ให้ Developer ดู
  res.status(err.status || 500).json({ 
    error: err.message || 'เกิดข้อผิดพลาดที่เซิร์ฟเวอร์ (Internal Server Error)' 
  });
});

// ==========================================
// 6. เริ่มต้นเปิดการทำงานของเซิร์ฟเวอร์
// ==========================================
const PORT = process.env.PORT || 5000;
app.listen(PORT, () => {
  console.log(` AIS APP Backend เซิร์ฟเวอร์ทำงานเรียบร้อยแล้วที่พอร์ต ${PORT}`);
  console.log(`- เช็คสถานะ API ได้ที่: http://localhost:${PORT}/api/courses/feed`);
});