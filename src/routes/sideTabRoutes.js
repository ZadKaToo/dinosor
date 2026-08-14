const express = require('express');
const router = express.Router();
const sideTabController = require('../controllers/sideTabController');
const verifyToken = require('../middlewares/auth');

// ล็อคความปลอดภัย: ทุกเมนูใน Side Tab ต้องผ่านการดักตรวจ Token
router.use(verifyToken);

router.get('/profile', sideTabController.getProfile);
router.get('/history', sideTabController.getHistory);
router.get('/saved', sideTabController.getSaved);
router.get('/settings', sideTabController.getSettings);
router.put('/settings', sideTabController.updateSettings);

module.exports = router;