const express = require('express');
const { listGuides, getGuide } = require('../controllers/guideController');

const router = express.Router();

router.get('/', listGuides);
router.get('/:id', getGuide);

module.exports = router;
