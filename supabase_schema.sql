-- Extensions
CREATE EXTENSION IF NOT EXISTS "pgcrypto";

-- ============================================================
-- 1. USERS (โปรไฟล์ ผูกกับ auth.users)
-- ============================================================
CREATE TABLE IF NOT EXISTS public.users (
  id            uuid PRIMARY KEY REFERENCES auth.users(id) ON DELETE CASCADE,
  email         varchar NOT NULL UNIQUE,
  full_name     varchar NOT NULL DEFAULT 'ผู้ใช้งาน',
  avatar_url    varchar,
  target_role   varchar,
  job_status    varchar DEFAULT 'seeking',
  readiness_score integer DEFAULT 0 CHECK (readiness_score >= 0 AND readiness_score <= 100),
  bio           text,
  phone         varchar,
  created_at    timestamp without time zone DEFAULT CURRENT_TIMESTAMP
);

-- ============================================================
-- 2. USER SETTINGS
-- ============================================================
CREATE TABLE IF NOT EXISTS public.user_settings (
  user_id             uuid PRIMARY KEY REFERENCES public.users(id) ON DELETE CASCADE,
  push_notifications  boolean DEFAULT true,
  dark_mode           boolean DEFAULT false,
  language            varchar DEFAULT 'TH',
  auto_save           boolean DEFAULT true,
  show_line_numbers   boolean DEFAULT true,
  sound_effects       boolean DEFAULT true,
  font_size           varchar DEFAULT 'ปกติ'
);

-- ============================================================
-- 3. USER PROGRESS (XP, streak)
-- ============================================================
CREATE TABLE IF NOT EXISTS public.user_progress (
  user_id         uuid PRIMARY KEY REFERENCES public.users(id) ON DELETE CASCADE,
  total_xp        integer NOT NULL DEFAULT 20,
  streak_days     integer NOT NULL DEFAULT 0,
  run_count       integer NOT NULL DEFAULT 0,
  last_active_date date,
  updated_at      timestamp without time zone DEFAULT CURRENT_TIMESTAMP
);

-- ============================================================
-- 4. SKILLS TAGS
-- ============================================================
CREATE TABLE IF NOT EXISTS public.skills_tags (
  id        serial PRIMARY KEY,
  name      varchar NOT NULL UNIQUE,
  category  varchar
);

-- ============================================================
-- 5. JOBS + JOB_SKILLS
-- ============================================================
CREATE TABLE IF NOT EXISTS public.jobs (
  id                          varchar PRIMARY KEY,
  title                       varchar NOT NULL,
  company                     varchar NOT NULL,
  location                    varchar NOT NULL,
  salary_min                  numeric NOT NULL,
  salary_max                  numeric NOT NULL,
  category                    varchar,
  experience                  varchar,
  missing_skill_recommendation varchar,
  created_at                  timestamp without time zone DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE IF NOT EXISTS public.job_skills (
  job_id    varchar NOT NULL REFERENCES public.jobs(id) ON DELETE CASCADE,
  skill_id  integer NOT NULL REFERENCES public.skills_tags(id) ON DELETE CASCADE,
  PRIMARY KEY (job_id, skill_id)
);

-- ============================================================
-- 6. COURSES + LESSONS + QUIZZES + SKILLS
-- ============================================================
CREATE TABLE IF NOT EXISTS public.courses (
  id              varchar PRIMARY KEY,
  title           varchar NOT NULL,
  category        varchar,
  summary         text,
  cover_image_url varchar,
  duration_text   varchar,
  difficulty_level varchar,
  rating          numeric DEFAULT 5.00,
  instructor      varchar,
  badge_earned    varchar,
  total_lessons   integer DEFAULT 1,
  like_count      integer DEFAULT 0,
  share_count     integer DEFAULT 0,
  created_at      timestamp without time zone DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE IF NOT EXISTS public.course_skills (
  course_id varchar NOT NULL REFERENCES public.courses(id) ON DELETE CASCADE,
  skill_id  integer NOT NULL REFERENCES public.skills_tags(id) ON DELETE CASCADE,
  PRIMARY KEY (course_id, skill_id)
);

CREATE TABLE IF NOT EXISTS public.course_lessons (
  id                        uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  course_id                 varchar NOT NULL REFERENCES public.courses(id) ON DELETE CASCADE,
  title                     varchar NOT NULL,
  content                   text NOT NULL,
  order_index               integer NOT NULL DEFAULT 1,
  estimated_read_time_mins  integer DEFAULT 5,
  created_at                timestamp without time zone DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE IF NOT EXISTS public.quizzes (
  id                    varchar PRIMARY KEY,
  course_id             varchar NOT NULL REFERENCES public.courses(id) ON DELETE CASCADE,
  lesson_order          integer DEFAULT 1,
  question              text NOT NULL,
  option_1              text NOT NULL,
  option_2              text NOT NULL,
  option_3              text NOT NULL,
  option_4              text NOT NULL,
  correct_answer_index  integer NOT NULL CHECK (correct_answer_index >= 0 AND correct_answer_index <= 3),
  explanation           text,
  created_at            timestamp without time zone DEFAULT CURRENT_TIMESTAMP
);

-- ============================================================
-- 7. USER COURSE HISTORY + SAVED + INTERACTIONS
-- ============================================================
CREATE TABLE IF NOT EXISTS public.user_course_history (
  id                uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id           uuid NOT NULL REFERENCES public.users(id) ON DELETE CASCADE,
  course_id         varchar NOT NULL REFERENCES public.courses(id) ON DELETE CASCADE,
  last_lesson_id    uuid REFERENCES public.course_lessons(id),
  status            varchar NOT NULL CHECK (status IN ('in_progress', 'completed')),
  progress_percent  integer DEFAULT 0 CHECK (progress_percent >= 0 AND progress_percent <= 100),
  last_accessed     timestamp without time zone DEFAULT CURRENT_TIMESTAMP,
  completed_at      timestamp without time zone
);

CREATE TABLE IF NOT EXISTS public.saved_courses (
  user_id   uuid NOT NULL REFERENCES public.users(id) ON DELETE CASCADE,
  course_id varchar NOT NULL REFERENCES public.courses(id) ON DELETE CASCADE,
  saved_at  timestamp without time zone DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (user_id, course_id)
);

CREATE TABLE IF NOT EXISTS public.user_interactions (
  id                uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id           uuid NOT NULL REFERENCES public.users(id) ON DELETE CASCADE,
  course_id         varchar NOT NULL REFERENCES public.courses(id) ON DELETE CASCADE,
  interaction_type  varchar NOT NULL CHECK (interaction_type IN ('view', 'like', 'skip', 'share', 'bookmark')),
  read_seconds      integer DEFAULT 0,
  created_at        timestamp without time zone DEFAULT CURRENT_TIMESTAMP
);

-- ============================================================
-- 8. SKILLS (certified + gaps)
-- ============================================================
CREATE TABLE IF NOT EXISTS public.user_certified_skills (
  id            uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id       uuid NOT NULL REFERENCES public.users(id) ON DELETE CASCADE,
  skill_name    varchar NOT NULL,
  issuer        varchar DEFAULT 'SkillUp Thailand',
  icon_name     varchar DEFAULT 'badge',
  is_verified   boolean DEFAULT true,
  certified_at  timestamp without time zone DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE IF NOT EXISTS public.user_skill_gaps (
  user_id         uuid NOT NULL REFERENCES public.users(id) ON DELETE CASCADE,
  skill_id        integer NOT NULL REFERENCES public.skills_tags(id) ON DELETE CASCADE,
  urgency_score   integer CHECK (urgency_score >= 1 AND urgency_score <= 100),
  is_acquired     boolean DEFAULT false,
  PRIMARY KEY (user_id, skill_id)
);

-- ============================================================
-- 9. BADGES
-- ============================================================
CREATE TABLE IF NOT EXISTS public.badges (
  id          varchar PRIMARY KEY,
  title       varchar NOT NULL,
  description text,
  icon_name   varchar
);

CREATE TABLE IF NOT EXISTS public.user_badges (
  user_id   uuid NOT NULL REFERENCES public.users(id) ON DELETE CASCADE,
  badge_id  varchar NOT NULL REFERENCES public.badges(id) ON DELETE CASCADE,
  earned_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (user_id, badge_id)
);

-- ============================================================
-- 10. MISSIONS (Live Sandbox)
-- ============================================================
CREATE TABLE IF NOT EXISTS public.missions (
  id            varchar PRIMARY KEY,
  track         varchar,
  title         varchar NOT NULL,
  description   text,
  xp_reward     integer NOT NULL DEFAULT 0,
  order_index   integer NOT NULL DEFAULT 1,
  starter_code  text,
  hint          text
);

CREATE TABLE IF NOT EXISTS public.user_missions (
  user_id         uuid NOT NULL REFERENCES public.users(id) ON DELETE CASCADE,
  mission_id      varchar NOT NULL REFERENCES public.missions(id) ON DELETE CASCADE,
  status          varchar NOT NULL DEFAULT 'not_started'
                  CHECK (status IN ('not_started', 'in_progress', 'completed')),
  submitted_code  text,
  completed_at    timestamp without time zone,
  PRIMARY KEY (user_id, mission_id)
);

-- ============================================================
-- 11. USER GUIDES
-- ============================================================
CREATE TABLE IF NOT EXISTS public.user_guides (
  id                  serial PRIMARY KEY,
  title               varchar NOT NULL,
  summary             text NOT NULL,
  content             text,
  category            varchar DEFAULT 'general',
  reading_time_mins   integer DEFAULT 5,
  views_count         integer DEFAULT 0,
  created_at          timestamp without time zone DEFAULT CURRENT_TIMESTAMP
);

-- ============================================================
-- 12. CHAT HISTORY (AI Mentor)
-- ============================================================
CREATE TABLE IF NOT EXISTS public.chat_history (
  id            bigint GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
  user_id       uuid REFERENCES public.users(id) ON DELETE SET NULL,
  user_message  text NOT NULL,
  bot_reply     text NOT NULL,
  created_at    timestamptz DEFAULT now()
);

-- ============================================================
-- 13. CAREER PROFILES
-- ============================================================
CREATE TABLE IF NOT EXISTS public.user_career_profiles (
  user_id           uuid PRIMARY KEY REFERENCES auth.users(id) ON DELETE CASCADE,
  keywords          jsonb NOT NULL DEFAULT '[]'::jsonb,
  careers_analysis  jsonb NOT NULL DEFAULT '[]'::jsonb,
  updated_at        timestamptz DEFAULT now()
);

-- ============================================================
-- TRIGGER: สร้าง public.users + user_settings + user_progress
--          อัตโนมัติเมื่อสมัครสมาชิก (auth.users insert)
-- ============================================================
CREATE OR REPLACE FUNCTION public.handle_new_user()
RETURNS TRIGGER
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
BEGIN
  INSERT INTO public.users (id, email, full_name, target_role)
  VALUES (
    NEW.id,
    COALESCE(NEW.email, ''),
    COALESCE(NEW.raw_user_meta_data->>'full_name', 'ผู้ใช้งาน'),
    NEW.raw_user_meta_data->>'target_role'
  )
  ON CONFLICT (id) DO NOTHING;

  INSERT INTO public.user_settings (user_id)
  VALUES (NEW.id)
  ON CONFLICT (user_id) DO NOTHING;

  INSERT INTO public.user_progress (user_id)
  VALUES (NEW.id)
  ON CONFLICT (user_id) DO NOTHING;

  RETURN NEW;
END;
$$;

DROP TRIGGER IF EXISTS on_auth_user_created ON auth.users;
CREATE TRIGGER on_auth_user_created
  AFTER INSERT ON auth.users
  FOR EACH ROW
  EXECUTE FUNCTION public.handle_new_user();

-- ============================================================
-- RLS — เปิดใช้ทุกตาราง และบังคับ login
-- ============================================================
ALTER TABLE public.users ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.user_settings ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.user_progress ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.skills_tags ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.jobs ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.job_skills ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.courses ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.course_skills ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.course_lessons ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.quizzes ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.user_course_history ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.saved_courses ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.user_interactions ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.user_certified_skills ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.user_skill_gaps ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.badges ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.user_badges ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.missions ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.user_missions ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.user_guides ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.chat_history ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.user_career_profiles ENABLE ROW LEVEL SECURITY;

-- ---- Policies: ข้อมูลส่วนตัว (เฉพาะเจ้าของ) ----
CREATE POLICY "users_select_own" ON public.users
  FOR SELECT TO authenticated USING (id = auth.uid());
CREATE POLICY "users_update_own" ON public.users
  FOR UPDATE TO authenticated USING (id = auth.uid());
CREATE POLICY "users_insert_own" ON public.users
  FOR INSERT TO authenticated WITH CHECK (id = auth.uid());

CREATE POLICY "settings_all_own" ON public.user_settings
  FOR ALL TO authenticated USING (user_id = auth.uid()) WITH CHECK (user_id = auth.uid());

CREATE POLICY "progress_all_own" ON public.user_progress
  FOR ALL TO authenticated USING (user_id = auth.uid()) WITH CHECK (user_id = auth.uid());

CREATE POLICY "course_history_all_own" ON public.user_course_history
  FOR ALL TO authenticated USING (user_id = auth.uid()) WITH CHECK (user_id = auth.uid());

CREATE POLICY "saved_courses_all_own" ON public.saved_courses
  FOR ALL TO authenticated USING (user_id = auth.uid()) WITH CHECK (user_id = auth.uid());

CREATE POLICY "interactions_all_own" ON public.user_interactions
  FOR ALL TO authenticated USING (user_id = auth.uid()) WITH CHECK (user_id = auth.uid());

CREATE POLICY "certified_skills_all_own" ON public.user_certified_skills
  FOR ALL TO authenticated USING (user_id = auth.uid()) WITH CHECK (user_id = auth.uid());

CREATE POLICY "skill_gaps_all_own" ON public.user_skill_gaps
  FOR ALL TO authenticated USING (user_id = auth.uid()) WITH CHECK (user_id = auth.uid());

CREATE POLICY "user_badges_all_own" ON public.user_badges
  FOR ALL TO authenticated USING (user_id = auth.uid()) WITH CHECK (user_id = auth.uid());

CREATE POLICY "user_missions_all_own" ON public.user_missions
  FOR ALL TO authenticated USING (user_id = auth.uid()) WITH CHECK (user_id = auth.uid());

CREATE POLICY "chat_history_all_own" ON public.chat_history
  FOR ALL TO authenticated USING (user_id = auth.uid()) WITH CHECK (user_id = auth.uid());

CREATE POLICY "career_profiles_all_own" ON public.user_career_profiles
  FOR ALL TO authenticated USING (user_id = auth.uid()) WITH CHECK (user_id = auth.uid());

-- ---- Policies: ข้อมูลสาธารณะ (อ่านได้หลัง login) ----
CREATE POLICY "skills_tags_select" ON public.skills_tags
  FOR SELECT TO authenticated USING (true);

CREATE POLICY "jobs_select" ON public.jobs
  FOR SELECT TO authenticated USING (true);
CREATE POLICY "job_skills_select" ON public.job_skills
  FOR SELECT TO authenticated USING (true);

CREATE POLICY "courses_select" ON public.courses
  FOR SELECT TO authenticated USING (true);
CREATE POLICY "course_skills_select" ON public.course_skills
  FOR SELECT TO authenticated USING (true);
CREATE POLICY "course_lessons_select" ON public.course_lessons
  FOR SELECT TO authenticated USING (true);
CREATE POLICY "quizzes_select" ON public.quizzes
  FOR SELECT TO authenticated USING (true);

CREATE POLICY "badges_select" ON public.badges
  FOR SELECT TO authenticated USING (true);

CREATE POLICY "missions_select" ON public.missions
  FOR SELECT TO authenticated USING (true);

CREATE POLICY "user_guides_select" ON public.user_guides
  FOR SELECT TO authenticated USING (true);
CREATE POLICY "user_guides_update_views" ON public.user_guides
  FOR UPDATE TO authenticated USING (true);

-- ============================================================
-- SEED DATA ตัวอย่าง (optional — ลบออกได้ถ้าไม่ต้องการ)
-- ============================================================

-- Skills
INSERT INTO public.skills_tags (name, category) VALUES
  ('Python', 'Programming'),
  ('JavaScript', 'Programming'),
  ('SQL', 'Data'),
  ('Git', 'Tools'),
  ('Linux', 'Ops'),
  ('Docker', 'DevOps'),
  ('AWS', 'Cloud'),
  ('React', 'Frontend'),
  ('Flutter', 'Mobile'),
  ('Cybersecurity Basics', 'Security')
ON CONFLICT (name) DO NOTHING;

-- Badges (ตรงกับ app_constants)
INSERT INTO public.badges (id, title, description, icon_name) VALUES
  ('first_run', 'First Run', 'รันโค้ดครั้งแรก', 'play_arrow'),
  ('first_pass', 'Test Passer', 'ผ่าน Test แรก', 'check_circle'),
  ('streak3', 'On Fire!', '3 วันติดต่อกัน', 'local_fire_department'),
  ('xp50', 'Rising Star', 'สะสม 50 XP', 'star'),
  ('xp100', 'Century Club', 'สะสม 100 XP', 'looks_one'),
  ('mission1', 'Mission Pro', 'ผ่าน Mission 1', 'flag'),
  ('coder', 'IT Practitioner', 'ใช้งาน Sandbox 10 ครั้ง', 'terminal'),
  ('xp200', 'Rocket Dev', 'สะสม 200 XP', 'rocket_launch')
ON CONFLICT (id) DO NOTHING;

-- Missions (ตรงกับ sandbox ใน app_constants)
INSERT INTO public.missions (id, track, title, description, xp_reward, order_index, starter_code, hint) VALUES
  ('greeting', 'swe', 'Greeting Automation Script',
   'รับชื่อผู้ใช้งานผ่าน input() แล้ว print คำทักทายว่า "Hello, [ชื่อ]!"',
   40, 1, '', 'ใช้ input() รับชื่อ แล้ว print ด้วย f-string หรือ +'),
  ('even_odd', 'swe', 'Server Health Even/Odd Checker',
   'รับตัวเลขจาก input() แล้วตรวจสอบว่าเป็นเลขคู่หรือคี่ พิมพ์ "Even" หรือ "Odd"',
   50, 2,
   'num = int(input(''Enter a number: ''))\nif num % 2 == 0:\n    print(''Even'')\nelse:\n    print(''Odd'')',
   'ใช้ % 2 == 0 เพื่อเช็คเลขคู่'),
  ('sum_list', 'data', 'Log Uptime Summation',
   'รับตัวเลขคั่นด้วย comma แล้วคำนวณผลรวม พิมพ์ "Total: X"',
   60, 3,
   'data = input(''Enter numbers (comma separated): '')\nnums = [int(x) for x in data.split('','')]\nprint(f"Total: {sum(nums)}")',
   'split(",") แล้วแปลงเป็น int'),
  ('password_strength', 'sec', 'Password Strength Auditor',
   'รับรหัสผ่าน ถ้าความยาว >= 8 พิมพ์ "Strong" ไม่เช่นนั้น "Weak"',
   70, 4,
   'pwd = input(''Enter password: '')\nif len(pwd) >= 8:\n    print(''Strong'')\nelse:\n    print(''Weak'')',
   'ใช้ len() เช็คความยาว')
ON CONFLICT (id) DO NOTHING;

-- Sample course
INSERT INTO public.courses (id, title, category, summary, duration_text, difficulty_level, instructor, total_lessons) VALUES
  ('py-basics', 'Python สำหรับมือใหม่', 'Programming',
   'เริ่มต้นเขียน Python จากศูนย์ จนสร้างสคริปต์ใช้งานได้จริง',
   '2 ชม.', 'Beginner', 'Skillpass Team', 3)
ON CONFLICT (id) DO NOTHING;

INSERT INTO public.course_lessons (course_id, title, content, order_index) VALUES
  ('py-basics', 'แนะนำ Python', 'Python เป็นภาษาที่อ่านง่าย ใช้ indent แทนวงเล็บ...', 1),
  ('py-basics', 'ตัวแปรและชนิดข้อมูล', 'ตัวแปรใน Python ไม่ต้องประกาศ type ล่วงหน้า...', 2),
  ('py-basics', 'เงื่อนไขและลูป', 'if/elif/else และ for/while เป็นพื้นฐานสำคัญ...', 3)
ON CONFLICT DO NOTHING;

INSERT INTO public.quizzes (id, course_id, lesson_order, question, option_1, option_2, option_3, option_4, correct_answer_index, explanation) VALUES
  ('q-py-1', 'py-basics', 1, 'Python ใช้สัญลักษณ์อะไรแทนการจัดกลุ่มโค้ด?',
   'วงเล็บปีกกา {}', 'indentation (ย่อหน้า)', 'วงเล็บเหลี่ยม []', 'เครื่องหมาย ;', 1,
   'Python ใช้ indentation เป็นโครงสร้างหลัก')
ON CONFLICT (id) DO NOTHING;

-- Sample job
INSERT INTO public.jobs (id, title, company, location, salary_min, salary_max, category, experience) VALUES
  ('job-jr-dev', 'Junior Python Developer', 'TechCorp Thailand', 'Bangkok', 25000, 35000, 'Software', '0-1 years')
ON CONFLICT (id) DO NOTHING;

-- Sample guide
INSERT INTO public.user_guides (title, summary, content, category, reading_time_mins) VALUES
  ('เริ่มต้นใช้งาน Skillpass', 'คู่มือสั้น ๆ สำหรับผู้ใช้ใหม่',
   '1. สมัครสมาชิก\n2. เลือกสายงาน\n3. เริ่มเรียนคอร์สและทำ Mission ใน Sandbox',
   'getting-started', 3)
ON CONFLICT DO NOTHING;

