const pool = require('../config/db');
const ApiError = require('../utils/ApiError');
const asyncHandler = require('../utils/asyncHandler');

const listJobs = asyncHandler(async (req, res) => {
  const { category, experience } = req.query;
  const conditions = [];
  const params = [];

  if (category) {
    params.push(category);
    conditions.push(`category = $${params.length}`);
  }
  if (experience) {
    params.push(experience);
    conditions.push(`experience = $${params.length}`);
  }

  const where = conditions.length ? `WHERE ${conditions.join(' AND ')}` : '';
  const result = await pool.query(`SELECT * FROM jobs ${where} ORDER BY created_at DESC`, params);
  res.json(result.rows);
});

const getJob = asyncHandler(async (req, res) => {
  const jobResult = await pool.query('SELECT * FROM jobs WHERE id = $1', [req.params.id]);
  if (!jobResult.rows[0]) throw new ApiError(404, 'ไม่พบตำแหน่งงานนี้');

  const skillsResult = await pool.query(
    `SELECT s.id, s.name, s.category FROM job_skills js
     JOIN skills_tags s ON s.id = js.skill_id WHERE js.job_id = $1`,
    [req.params.id]
  );

  res.json({ ...jobResult.rows[0], required_skills: skillsResult.rows });
});

module.exports = { listJobs, getJob };
