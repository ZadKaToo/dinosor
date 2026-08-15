const pool = require('../config/db'); // อย่าลืม import pool กลับมา
const ApiError = require('../utils/ApiError');
const asyncHandler = require('../utils/asyncHandler');

// ฟังก์ชันเรียก AI ตัวเดิม
async function callAiBackend(message, history) {
  const controller = new AbortController();
  const timeout = setTimeout(
    () => controller.abort(),
    Number(process.env.AI_MENTOR_TIMEOUT_MS) || 15000
  );

  try {
    const response = await fetch(process.env.AI_MENTOR_URL, {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({ message, history }),
      signal: controller.signal,
    });

    if (!response.ok) {
      throw new ApiError(502, `AI backend ตอบกลับผิดพลาด (${response.status})`);
    }

    const data = await response.json();
    return data.reply || 'ไม่สามารถดึงข้อมูลคำตอบได้';
  } catch (err) {
    if (err.name === 'AbortError') {
      throw new ApiError(504, 'AI backend ตอบสนองช้าเกินไป');
    }
    throw err;
  } finally {
    clearTimeout(timeout);
  }
}

// 1. ฟังก์ชันสำหรับดึงประวัติการแชท (เผื่อต้องการโหลดตอนเปิดหน้าแชท)
const getChatHistory = asyncHandler(async (req, res) => {
  const result = await pool.query(
    'SELECT * FROM chat_history WHERE user_id = $1 ORDER BY created_at ASC',
    [req.userId]
  );
  res.json(result.rows);
});

// 2. ฟังก์ชันส่งข้อความและบันทึกลง DB
const sendMentorMessage = asyncHandler(async (req, res) => {
  const { message, history } = req.body;
  
  if (!message || !message.trim()) {
    throw new ApiError(400, 'ต้องระบุ message');
  }

  // ส่งข้อความไปหา AI
  const reply = await callAiBackend(message, history || []);

  // บันทึกคำถามและคำตอบลง Database ตาราง chat_history
  await pool.query(
    `INSERT INTO chat_history (user_id, user_message, bot_reply)
     VALUES ($1, $2, $3)`,
    [req.userId, message, reply]
  );

  // ส่งคำตอบกลับให้ Frontend
  res.json({ reply });
});

// ส่งออกทั้งสองฟังก์ชัน
module.exports = { sendMentorMessage, getChatHistory };