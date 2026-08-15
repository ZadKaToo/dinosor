const express = require('express');
const auth = require('../middleware/auth');
const { updateProfile, getSettings, updateSettings } = require('../controllers/userController');

const router = express.Router();

router.use(auth);
router.patch('/me', updateProfile);
router.get('/me/settings', getSettings);
router.patch('/me/settings', updateSettings);

module.exports = router;
