import express from 'express';
import { registerUser, loginUser } from '../controllers/authController.js';

const router = express.Router();

router.post('/register', registerUser);
router.post('/login', loginUser);
// Note: หน้า 'ลืมรหัสผ่าน' สามารถทำเพิ่มเป็น router.post('/forgot-password', forgotPassword) ได้ในอนาคต

export default router;