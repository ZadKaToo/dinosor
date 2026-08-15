# LearnPro Backend

Express + PostgreSQL API สำหรับแอป LearnPro (Flutter)

## 1. ติดตั้ง

```bash
cd learnpro-backend
npm install
cp .env.example .env
```

แก้ `.env`:
- `DATABASE_URL` — connection string ของ Postgres
- `JWT_SECRET` — สุ่มสตริงยาวๆ
- `AI_MENTOR_URL` — URL ของ AI backend ที่มีอยู่แล้ว (ตัวที่ตอนนี้รันผ่าน loca.lt)
  - backend นี้จะยิง `POST { message, history }` ไปที่ URL นี้ และคาดหวัง response เป็น `{ reply }`
  - ถ้า AI backend ของคุณรับ/ส่งข้อมูลคนละรูปแบบ ให้แก้ฟังก์ชัน `callAiBackend()` ใน `src/controllers/chatController.js`

## 2. สร้างฐานข้อมูล

```bash
psql -U your_user -d learnpro -f path/to/your/schema.sql
psql -U your_user -d learnpro -f migrations/001_gamification_and_fixes.sql
```

migration ตัวที่สองจำเป็น — เพิ่มตาราง `user_progress`, `badges`, `user_badges`, `missions`,
`user_missions` ที่ schema เดิมยังไม่มี (แอป Flutter เก็บ XP/streak/badges ไว้ใน local state
เท่านั้น ตอนนี้ backend ต้องมีตารางพวกนี้เพื่อ persist ข้อมูลจริง) และเพิ่ม unique constraint
ที่ `user_course_history` ที่จำเป็นสำหรับการ upsert

## 3. รัน

```bash
npm run dev   # หรือ npm start
```

Server จะรันที่ `http://localhost:4000` (หรือ `PORT` ที่ตั้งไว้), เช็คได้ที่ `GET /health`

## 4. สิ่งที่ต้องแก้ฝั่ง Flutter

โค้ดปัจจุบันใน `AIMentorChatScreen._sendMessage()` ยิง `POST /api/mentor` โดยไม่มี
`Authorization` header — แต่ endpoint นี้ต้อง login ก่อน (เพราะต้องรู้ว่าข้อความเป็นของ
user คนไหนเพื่อบันทึกลง `chat_sessions`) ต้องเพิ่ม:

1. หน้า login/register ที่เก็บ `token` จาก response ของ `/api/auth/login`
2. แนบ header `Authorization: Bearer <token>` ทุก request ที่ต้อง auth (ดูรายการด้านล่าง)
3. เปลี่ยน `AppState` (XP, streak, badges, missions) จาก local state ล้วนๆ ให้ดึงจาก
   `GET /api/progress/me` ตอนเปิดแอป แล้วเรียก `POST /api/progress/me/xp` และ
   `POST /api/progress/me/run` แทนการ mutate ตัวแปรในเครื่องตรงๆ

## 5. Endpoint ทั้งหมด

`🔒` = ต้องแนบ `Authorization: Bearer <token>`

### Auth
- `POST /api/auth/register` `{ email, password, full_name }`
- `POST /api/auth/login` `{ email, password }`
- `GET /api/auth/me` 🔒

### Users
- `PATCH /api/users/me` 🔒 `{ full_name?, avatar_url?, target_role?, bio?, phone? }`
- `GET /api/users/me/settings` 🔒
- `PATCH /api/users/me/settings` 🔒 `{ push_notifications?, dark_mode?, language? }`

### Progress (XP/streak/badges)
- `GET /api/progress/me` 🔒
- `POST /api/progress/me/xp` 🔒 `{ amount }` — คูณ streak multiplier ให้อัตโนมัติ
- `POST /api/progress/me/run` 🔒 — เรียกทุกครั้งที่รันโค้ดใน Sandbox

### Missions
- `GET /api/missions?track=swe`
- `GET /api/missions/mine` 🔒
- `GET /api/missions/:id`
- `POST /api/missions/:id/submit` 🔒 `{ code, passed }`

### Courses
- `GET /api/courses?category=`
- `GET /api/courses/:id`
- `GET /api/courses/:id/lessons`
- `GET /api/courses/:id/quizzes`
- `POST /api/courses/:id/save` 🔒
- `DELETE /api/courses/:id/save` 🔒
- `GET /api/courses/saved/mine` 🔒
- `GET /api/courses/history/mine` 🔒
- `PUT /api/courses/:id/progress` 🔒 `{ progress_percent, last_lesson_id, status }`

### Jobs
- `GET /api/jobs?category=&experience=`
- `GET /api/jobs/:id`

### Quizzes
- `POST /api/quizzes/:id/answer` 🔒 `{ selected_index }`

### Skills
- `GET /api/skills/tags`
- `GET /api/skills/gaps/mine` 🔒
- `GET /api/skills/certified/mine` 🔒

### Guides
- `GET /api/guides?category=`
- `GET /api/guides/:id`

### AI Mentor Chat
- `POST /api/mentor` 🔒 `{ message, session_id? }` → `{ reply, session_id }`
  (compatible กับโค้ด Flutter เดิม แค่ต้องเพิ่ม auth header)
- `GET /api/chat/sessions` 🔒
- `GET /api/chat/sessions/:id/messages` 🔒

## 6. โครงสร้างโปรเจกต์

```
src/
├── config/db.js          # pg connection pool
├── middleware/
│   ├── auth.js           # ตรวจ JWT
│   └── errorHandler.js   # error handling กลาง
├── controllers/           # business logic ต่อ resource
├── routes/                 # express routers ต่อ resource
├── utils/
│   ├── ApiError.js
│   └── asyncHandler.js
├── app.js                 # ประกอบ express app + mount routes
└── server.js               # entry point
migrations/
└── 001_gamification_and_fixes.sql
```

## หมายเหตุ

- ใช้ Node.js 18 ขึ้นไป (ใช้ global `fetch` ในการเรียก AI backend)
- Error response ทั้งหมดอยู่ในรูป `{ "error": "ข้อความ" }`
- ยังไม่มี input validation library (เช่น zod/Joi) — ตอนนี้ validate มือแบบง่ายๆ ถ้าจะขึ้น
  production จริงแนะนำให้เพิ่ม
