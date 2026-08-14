const supabase = require('../config/supabase');
const bcrypt = require('bcryptjs');
const jwt = require('jsonwebtoken');

// ฟังก์ชันสมัครสมาชิก
exports.register = async (req, res) => {
  const { email, password, full_name } = req.body;
  
  // เข้ารหัสผ่านก่อนบันทึกลงฐานข้อมูลเพื่อความปลอดภัย
  const hashedPassword = await bcrypt.hash(password, 10);

  const { data, error } = await supabase
    .from('users')
    .insert([{ email, password_hash: hashedPassword, full_name }])
    .select()
    .single();

  if (error) return res.status(400).json({ error: error.message });

  // สร้างการตั้งค่าเริ่มต้นให้ User
  await supabase.from('user_settings').insert([{ user_id: data.id }]);

  res.status(201).json({ message: 'สมัครสมาชิกสำเร็จ', user: data });
};

// ฟังก์ชันล็อกอิน
exports.login = async (req, res) => {
  const { email, password } = req.body;

  const { data: user, error } = await supabase.from('users').select('*').eq('email', email).single();
  if (error || !user) return res.status(401).json({ error: 'อีเมลหรือรหัสผ่านไม่ถูกต้อง' });

  // ตรวจสอบรหัสผ่าน
  const isValid = await bcrypt.compare(password, user.password_hash);
  if (!isValid) return res.status(401).json({ error: 'อีเมลหรือรหัสผ่านไม่ถูกต้อง' });

  // สร้างบัตรผ่าน (Token)
  const token = jwt.sign({ id: user.id }, process.env.JWT_SECRET, { expiresIn: '7d' });
  res.json({ message: 'เข้าสู่ระบบสำเร็จ', token, user });
};

