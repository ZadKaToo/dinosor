const express = require('express');
const auth = require('../middleware/auth');
const { listSkillsTags, mySkillGaps, myCertifiedSkills } = require('../controllers/skillController');

const router = express.Router();

router.get('/tags', listSkillsTags);
router.get('/gaps/mine', auth, mySkillGaps);
router.get('/certified/mine', auth, myCertifiedSkills);

module.exports = router;
