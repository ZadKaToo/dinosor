const pool = require('../config/db');
const ApiError = require('../utils/ApiError');
const asyncHandler = require('../utils/asyncHandler');

const listGuides = asyncHandler(async (req, res) => {
  const { category } = req.query;
  const params = [];
  let where = '';
  if (category) {
    params.push(category);
    where = 'WHERE category = $1';
  }
  const result = await pool.query(
    `SELECT id, title, summary, category, reading_time_mins, views_count
     FROM user_guides ${where} ORDER BY created_at DESC`,
    params
  );
  res.json(result.rows);
});

const getGuide = asyncHandler(async (req, res) => {
  const result = await pool.query(
    'UPDATE user_guides SET views_count = views_count + 1 WHERE id = $1 RETURNING *',
    [req.params.id]
  );
  if (!result.rows[0]) throw new ApiError(404, 'ไม่พบบทความนี้');
  res.json(result.rows[0]);
});

module.exports = { listGuides, getGuide };
