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

// ลบการทำงานที่เกี่ยวกับ Database ออกทั้งหมด
const sendMentorMessage = asyncHandler(async (req, res) => {
  const { message, history } = req.body; // รับ history จากฝั่ง Frontend มาเลย (ถ้ามี)
  
  if (!message || !message.trim()) {
    throw new ApiError(400, 'ต้องระบุ message');
  }

  // ส่งข้อความไปหา AI โดยตรง
  const reply = await callAiBackend(message, history || []);

  // ส่งคำตอบกลับให้ Frontend ทันที
  res.json({ reply });
});

// ส่งออกแค่ sendMentorMessage (ลบ listSessions และ getSessionMessages ทิ้งไปเลย เพราะไม่มี DB ให้ดึงแล้ว)
module.exports = { sendMentorMessage };