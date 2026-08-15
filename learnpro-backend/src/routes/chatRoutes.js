const express = require('express');
const auth = require('../middleware/auth');
const { listSessions, getSessionMessages } = require('../controllers/chatController');

const router = express.Router();

router.use(auth);

module.exports = router;
