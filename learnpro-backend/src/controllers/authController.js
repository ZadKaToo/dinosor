const bcrypt = require('bcryptjs');
const jwt = require('jsonwebtoken');
const pool = require('../config/db');
const ApiError = require('../utils/ApiError');
const asyncHandler = require('../utils/asyncHandler');

function signToken(userId) {
  return jwt.sign({ sub: userId }, process.env.JWT_SECRET, {
    expiresIn: process.env.JWT_EXPIRES_IN || '7d',
  });
}

const register = asyncHandler(async (req, res) => {
  const { email, password, full_name } = req.body;

  if (!email || !password || !full_name) {
    throw new ApiError(400, 'ต้องระบุ email, password และ full_name');
  }
  if (password.length < 6) {
    throw new ApiError(400, 'password ต้องมีอย่างน้อย 6 ตัวอักษร');
  }

  const passwordHash = await bcrypt.hash(password, 10);

  const client = await pool.connect();
  try {
    await client.query('BEGIN');

    const userResult = await client.query(
      `INSERT INTO users (email, password_hash, full_name)
       VALUES ($1, $2, $3)
       RETURNING id, email, full_name, target_role, job_status, readiness_score, created_at`,
      [email.toLowerCase().trim(), passwordHash, full_name]
    );
    const user = userResult.rows[0];

    await client.query('INSERT INTO user_settings (user_id) VALUES ($1)', [user.id]);
    await client.query('INSERT INTO user_progress (user_id) VALUES ($1)', [user.id]);

    await client.query('COMMIT');

    const token = signToken(user.id);
    res.status(201).json({ user, token });
  } catch (err) {
    await client.query('ROLLBACK');
    throw err;
  } finally {
    client.release();
  }
});

const login = asyncHandler(async (req, res) => {
  const { email, password } = req.body;
  if (!email || !password) {
    throw new ApiError(400, 'ต้องระบุ email และ password');
  }

  const result = await pool.query(
    `SELECT id, email, full_name, password_hash, target_role, job_status, readiness_score
     FROM users WHERE email = $1`,
    [email.toLowerCase().trim()]
  );
  const user = result.rows[0];

  if (!user || !(await bcrypt.compare(password, user.password_hash))) {
    throw new ApiError(401, 'อีเมลหรือรหัสผ่านไม่ถูกต้อง');
  }

  delete user.password_hash;
  const token = signToken(user.id);
  res.json({ user, token });
});

const me = asyncHandler(async (req, res) => {
  // ใช้ LEFT JOIN เพื่อดึงข้อมูล Progress และ Settings ออกมาพร้อมกับ User
  const result = await pool.query(
    `SELECT u.id, u.email, u.full_name, u.avatar_url, u.target_role, 
            p.total_xp, p.streak_days, p.run_count,
            s.dark_mode, s.language
     FROM users u
     LEFT JOIN user_progress p ON u.id = p.user_id
     LEFT JOIN user_settings s ON u.id = s.user_id
     WHERE u.id = $1`,
    [req.userId]
  );

  if (!result.rows[0]) throw new ApiError(404, 'ไม่พบผู้ใช้');
  res.json(result.rows[0]);
});

module.exports = { register, login, me };
