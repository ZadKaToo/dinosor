const express = require('express');
const router = express.Router();
const courseController = require('../controllers/courseController');
const verifyToken = require('../middlewares/auth');

// กำหนด URL สำหรับดึงหน้า Feed (ต้องล็อคอินก่อน)
router.get('/feed', verifyToken, courseController.getFeed);

module.exports = router;