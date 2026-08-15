const express = require('express');
const auth = require('../middleware/auth');
const { answerQuiz } = require('../controllers/quizController');

const router = express.Router();

router.post('/:id/answer', auth, answerQuiz);

module.exports = router;
