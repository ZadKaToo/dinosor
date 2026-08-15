const pool = require('../config/db');
const ApiError = require('../utils/ApiError');
const asyncHandler = require('../utils/asyncHandler');

const getCourseQuizzes = asyncHandler(async (req, res) => {
  // correct_answer_index is withheld here so it never appears in the network
  // payload before the user answers; it's only returned by answerQuiz below.
  const result = await pool.query(
    `SELECT id, lesson_order, question, option_1, option_2, option_3, option_4
     FROM quizzes WHERE course_id = $1 ORDER BY lesson_order ASC`,
    [req.params.id]
  );
  res.json(result.rows);
});

const answerQuiz = asyncHandler(async (req, res) => {
  const { selected_index } = req.body;
  if (![0, 1, 2, 3].includes(selected_index)) {
    throw new ApiError(400, 'selected_index ต้องเป็น 0-3');
  }

  const result = await pool.query(
    'SELECT correct_answer_index, explanation FROM quizzes WHERE id = $1',
    [req.params.id]
  );
  if (!result.rows[0]) throw new ApiError(404, 'ไม่พบคำถามนี้');

  const { correct_answer_index, explanation } = result.rows[0];
  res.json({
    correct: selected_index === correct_answer_index,
    correct_answer_index,
    explanation,
  });
});

module.exports = { getCourseQuizzes, answerQuiz };
