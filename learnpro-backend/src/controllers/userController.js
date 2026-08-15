const pool = require('../config/db');
const ApiError = require('../utils/ApiError');
const asyncHandler = require('../utils/asyncHandler');

const updateProfile = asyncHandler(async (req, res) => {
  const { full_name, avatar_url, target_role, bio, phone } = req.body;

  const result = await pool.query(
    `UPDATE users SET
       full_name = COALESCE($1, full_name),
       avatar_url = COALESCE($2, avatar_url),
       target_role = COALESCE($3, target_role),
       bio = COALESCE($4, bio),
       phone = COALESCE($5, phone)
     WHERE id = $6
     RETURNING id, email, full_name, avatar_url, target_role, job_status, readiness_score, bio, phone`,
    [full_name, avatar_url, target_role, bio, phone, req.userId]
  );

  if (!result.rows[0]) throw new ApiError(404, 'ไม่พบผู้ใช้');
  res.json(result.rows[0]);
});

const getSettings = asyncHandler(async (req, res) => {
  const result = await pool.query('SELECT * FROM user_settings WHERE user_id = $1', [req.userId]);
  if (!result.rows[0]) throw new ApiError(404, 'ไม่พบการตั้งค่า');
  res.json(result.rows[0]);
});

const updateSettings = asyncHandler(async (req, res) => {
  const { push_notifications, dark_mode, language } = req.body;
  const result = await pool.query(
    `UPDATE user_settings SET
       push_notifications = COALESCE($1, push_notifications),
       dark_mode = COALESCE($2, dark_mode),
       language = COALESCE($3, language)
     WHERE user_id = $4
     RETURNING *`,
    [push_notifications, dark_mode, language, req.userId]
  );
  if (!result.rows[0]) throw new ApiError(404, 'ไม่พบการตั้งค่า');
  res.json(result.rows[0]);
});

module.exports = { updateProfile, getSettings, updateSettings };
