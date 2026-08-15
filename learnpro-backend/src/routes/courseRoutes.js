const express = require('express');
const auth = require('../middleware/auth');
const {
  listCourses,
  getCourse,
  getCourseLessons,
  saveCourse,
  unsaveCourse,
  mySavedCourses,
  myCourseHistory,
  upsertCourseProgress,
} = require('../controllers/courseController');
const { getCourseQuizzes } = require('../controllers/quizController');

const router = express.Router();

router.get('/', listCourses);
router.get('/saved/mine', auth, mySavedCourses); // must come before '/:id'
router.get('/history/mine', auth, myCourseHistory); // must come before '/:id'
router.get('/:id', getCourse);
router.get('/:id/lessons', getCourseLessons);
router.get('/:id/quizzes', getCourseQuizzes);
router.post('/:id/save', auth, saveCourse);
router.delete('/:id/save', auth, unsaveCourse);
router.put('/:id/progress', auth, upsertCourseProgress);

module.exports = router;
