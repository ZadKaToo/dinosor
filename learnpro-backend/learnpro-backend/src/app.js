require('dotenv').config();
const express = require('express');
const cors = require('cors');
const morgan = require('morgan');

const authRoutes = require('./routes/authRoutes');
const userRoutes = require('./routes/userRoutes');
const progressRoutes = require('./routes/progressRoutes');
const missionRoutes = require('./routes/missionRoutes');
const courseRoutes = require('./routes/courseRoutes');
const jobRoutes = require('./routes/jobRoutes');
const quizRoutes = require('./routes/quizRoutes');
const skillRoutes = require('./routes/skillRoutes');
const guideRoutes = require('./routes/guideRoutes');
const { sendMentorMessage } = require('./controllers/chatController');
const auth = require('./middleware/auth');
const errorHandler = require('./middleware/errorHandler');

const app = express();

app.use(cors({ origin: process.env.CORS_ORIGIN || '*' }));
app.use(express.json());
app.use(morgan('dev'));

app.get('/health', (req, res) => res.json({ status: 'ok' }));

app.use('/api/auth', authRoutes);
app.use('/api/users', userRoutes);
app.use('/api/progress', progressRoutes);
app.use('/api/missions', missionRoutes);
app.use('/api/courses', courseRoutes);
app.use('/api/jobs', jobRoutes);
app.use('/api/quizzes', quizRoutes);
app.use('/api/skills', skillRoutes);
app.use('/api/guides', guideRoutes);

// Backward-compatible with the existing Flutter client (AIMentorChatScreen
// currently POSTs here directly). Requires an Authorization header — update
// the Flutter _sendMessage() call to attach one once login is wired up.
app.post('/api/mentor', auth, sendMentorMessage);

app.use((req, res) => res.status(404).json({ error: 'Not found' }));
app.use(errorHandler);

module.exports = app;
