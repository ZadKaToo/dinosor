const express = require('express');
const { listJobs, getJob } = require('../controllers/jobController');

const router = express.Router();

router.get('/', listJobs);
router.get('/:id', getJob);

module.exports = router;
