const pool = require('../config/db');
const asyncHandler = require('../utils/asyncHandler');

const listSkillsTags = asyncHandler(async (req, res) => {
  const result = await pool.query('SELECT * FROM skills_tags ORDER BY category, name');
  res.json(result.rows);
});

const mySkillGaps = asyncHandler(async (req, res) => {
  const result = await pool.query(
    `SELECT g.urgency_score, g.is_acquired, s.id, s.name, s.category
     FROM user_skill_gaps g JOIN skills_tags s ON s.id = g.skill_id
     WHERE g.user_id = $1 ORDER BY g.urgency_score DESC`,
    [req.userId]
  );
  res.json(result.rows);
});

const myCertifiedSkills = asyncHandler(async (req, res) => {
  const result = await pool.query(
    'SELECT * FROM user_certified_skills WHERE user_id = $1 ORDER BY certified_at DESC',
    [req.userId]
  );
  res.json(result.rows);
});

module.exports = { listSkillsTags, mySkillGaps, myCertifiedSkills };
