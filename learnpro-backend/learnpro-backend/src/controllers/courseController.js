const pool = require('../config/db');
const ApiError = require('../utils/ApiError');
const asyncHandler = require('../utils/asyncHandler');

const listCourses = asyncHandler(async (req, res) => {
  const { category } = req.query;
  const params = [];
  let where = '';
  if (category) {
    params.push(category);
    where = 'WHERE category = $1';
  }
  const result = await pool.query(
    `SELECT id, title, category, summary, cover_image_url, duration_text,
            difficulty_level, rating, instructor, total_lessons, like_count
     FROM courses ${where} ORDER BY created_at DESC`,
    params
  );
  res.json(result.rows);
});

const getCourse = asyncHandler(async (req, res) => {
  const courseResult = await pool.query('SELECT * FROM courses WHERE id = $1', [req.params.id]);
  if (!courseResult.rows[0]) throw new ApiError(404, 'ไม่พบคอร์สนี้');

  const skillsResult = await pool.query(
    `SELECT s.id, s.name, s.category FROM course_skills cs
     JOIN skills_tags s ON s.id = cs.skill_id WHERE cs.course_id = $1`,
    [req.params.id]
  );

  res.json({ ...courseResult.rows[0], skills: skillsResult.rows });
});

const getCourseLessons = asyncHandler(async (req, res) => {
  const result = await pool.query(
    `SELECT id, title, content, order_index, estimated_read_time_mins
     FROM course_lessons WHERE course_id = $1 ORDER BY order_index ASC`,
    [req.params.id]
  );
  res.json(result.rows);
});

const saveCourse = asyncHandler(async (req, res) => {
  await pool.query(
    'INSERT INTO saved_courses (user_id, course_id) VALUES ($1, $2) ON CONFLICT DO NOTHING',
    [req.userId, req.params.id]
  );
  res.status(201).json({ saved: true });
});

const unsaveCourse = asyncHandler(async (req, res) => {
  await pool.query('DELETE FROM saved_courses WHERE user_id = $1 AND course_id = $2', [
    req.userId,
    req.params.id,
  ]);
  res.json({ saved: false });
});

const mySavedCourses = asyncHandler(async (req, res) => {
  const result = await pool.query(
    `SELECT c.* FROM saved_courses sc JOIN courses c ON c.id = sc.course_id
     WHERE sc.user_id = $1 ORDER BY sc.saved_at DESC`,
    [req.userId]
  );
  res.json(result.rows);
});

const myCourseHistory = asyncHandler(async (req, res) => {
  const result = await pool.query(
    `SELECT h.*, c.title, c.cover_image_url FROM user_course_history h
     JOIN courses c ON c.id = h.course_id
     WHERE h.user_id = $1 ORDER BY h.last_accessed DESC`,
    [req.userId]
  );
  res.json(result.rows);
});

// Requires the uq_user_course unique constraint added in
// migrations/001_gamification_and_fixes.sql for ON CONFLICT to work.
const upsertCourseProgress = asyncHandler(async (req, res) => {
  const { progress_percent, last_lesson_id, status } = req.body;
  const result = await pool.query(
    `INSERT INTO user_course_history
       (user_id, course_id, progress_percent, last_lesson_id, status, last_accessed, completed_at)
     VALUES ($1, $2, $3, $4, $5, NOW(), CASE WHEN $5 = 'completed' THEN NOW() ELSE NULL END)
     ON CONFLICT (user_id, course_id) DO UPDATE SET
       progress_percent = EXCLUDED.progress_percent,
       last_lesson_id = EXCLUDED.last_lesson_id,
       status = EXCLUDED.status,
       last_accessed = NOW(),
       completed_at = COALESCE(user_course_history.completed_at, EXCLUDED.completed_at)
     RETURNING *`,
    [req.userId, req.params.id, progress_percent, last_lesson_id, status]
  );
  res.json(result.rows[0]);
});

module.exports = {
  listCourses,
  getCourse,
  getCourseLessons,
  saveCourse,
  unsaveCourse,
  mySavedCourses,
  myCourseHistory,
  upsertCourseProgress,
};
