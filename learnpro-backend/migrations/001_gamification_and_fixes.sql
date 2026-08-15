-- ========================================================
-- Adds tables for gamification features that already exist in the Flutter
-- app's local AppState (XP, streak, run count, badges, missions) but have
-- no backing tables in the original schema. Run this AFTER your schema.sql.
-- ========================================================

CREATE TABLE IF NOT EXISTS user_progress (
    user_id UUID PRIMARY KEY REFERENCES users(id) ON DELETE CASCADE,
    total_xp INT NOT NULL DEFAULT 20,
    streak_days INT NOT NULL DEFAULT 0,
    run_count INT NOT NULL DEFAULT 0,
    last_active_date DATE,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE IF NOT EXISTS badges (
    id VARCHAR(50) PRIMARY KEY,
    title VARCHAR(255) NOT NULL,
    description TEXT,
    icon_name VARCHAR(50)
);

CREATE TABLE IF NOT EXISTS user_badges (
    user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    badge_id VARCHAR(50) NOT NULL REFERENCES badges(id) ON DELETE CASCADE,
    earned_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    PRIMARY KEY (user_id, badge_id)
);

CREATE TABLE IF NOT EXISTS missions (
    id VARCHAR(50) PRIMARY KEY,
    track VARCHAR(50),
    title VARCHAR(255) NOT NULL,
    description TEXT,
    xp_reward INT NOT NULL DEFAULT 0,
    order_index INT NOT NULL DEFAULT 1,
    starter_code TEXT,
    hint TEXT
);

CREATE TABLE IF NOT EXISTS user_missions (
    user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    mission_id VARCHAR(50) NOT NULL REFERENCES missions(id) ON DELETE CASCADE,
    status VARCHAR(20) NOT NULL DEFAULT 'not_started'
        CHECK (status IN ('not_started', 'in_progress', 'completed')),
    submitted_code TEXT,
    completed_at TIMESTAMP,
    PRIMARY KEY (user_id, mission_id)
);

-- The original schema gives user_course_history its own UUID primary key with
-- no unique constraint on (user_id, course_id). The backend needs that
-- constraint to upsert progress (ON CONFLICT) when a user resumes a course.
ALTER TABLE user_course_history
    ADD CONSTRAINT uq_user_course UNIQUE (user_id, course_id);

-- Seed badge definitions matching AppState.earnedBadges values in the Flutter app
INSERT INTO badges (id, title, description, icon_name) VALUES
    ('first_run', 'First Run', 'รันโค้ดครั้งแรกใน Sandbox', 'play_circle'),
    ('coder', 'Coder', 'รันโค้ดครบ 10 ครั้ง', 'terminal'),
    ('mission1', 'Mission Complete', 'ทำภารกิจแรกสำเร็จ', 'flag'),
    ('first_pass', 'First XP', 'สะสม XP ครบ 40', 'star'),
    ('xp50', 'XP 50', 'สะสม XP ครบ 50', 'star_half'),
    ('xp100', 'XP 100', 'สะสม XP ครบ 100', 'stars'),
    ('xp200', 'XP 200', 'สะสม XP ครบ 200', 'auto_awesome')
ON CONFLICT (id) DO NOTHING;

-- Seed the first mission to match the "Greeting Automation Script" in the app
INSERT INTO missions (id, track, title, description, xp_reward, order_index) VALUES
    ('mission_greeting', 'swe', 'Greeting Automation Script',
     'รับชื่อผู้ใช้งานด้วย input() แล้ว print คำทักทายว่า "Hello, [ชื่อ]!"', 40, 1)
ON CONFLICT (id) DO NOTHING;
