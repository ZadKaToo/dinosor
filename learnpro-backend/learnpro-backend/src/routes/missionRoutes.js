const express = require('express');
const auth = require('../middleware/auth');
const {
  listMissions,
  getMission,
  myMissions,
  submitMission,
} = require('../controllers/missionController');

const router = express.Router();

router.get('/', listMissions);
router.get('/mine', auth, myMissions); // must come before '/:id'
router.get('/:id', getMission);
router.post('/:id/submit', auth, submitMission);

module.exports = router;
