const express = require('express');
const auth = require('../middleware/auth');
const { getMyProgress, addXp, incrementRunCount } = require('../controllers/progressController');

const router = express.Router();

router.use(auth);
router.get('/me', getMyProgress);
router.post('/me/xp', addXp);
router.post('/me/run', incrementRunCount);

module.exports = router;
