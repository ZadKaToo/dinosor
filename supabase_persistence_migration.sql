-- 1) บทสนทนา AI Mentor (มีตาราง chat_history อยู่แล้ว — เพิ่มคอลัมน์ session)
ALTER TABLE public.chat_history
  ADD COLUMN IF NOT EXISTS session_id uuid DEFAULT gen_random_uuid();

CREATE INDEX IF NOT EXISTS idx_chat_history_user_created
  ON public.chat_history (user_id, created_at DESC);

-- 2) ไฟล์โปรเจกต์ใน Sandbox (main.py และไฟล์อื่นต่อ user)
CREATE TABLE IF NOT EXISTS public.user_sandbox_files (
  id          uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id     uuid NOT NULL REFERENCES public.users(id) ON DELETE CASCADE,
  file_name   varchar NOT NULL,
  content     text NOT NULL DEFAULT '',
  created_at  timestamptz DEFAULT now(),
  updated_at  timestamptz DEFAULT now(),
  UNIQUE (user_id, file_name)
);

CREATE INDEX IF NOT EXISTS idx_sandbox_files_user
  ON public.user_sandbox_files (user_id);

-- 3) ประวัติการรันโค้ด
CREATE TABLE IF NOT EXISTS public.user_code_runs (
  id            uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id       uuid NOT NULL REFERENCES public.users(id) ON DELETE CASCADE,
  file_name     varchar DEFAULT 'main.py',
  code          text NOT NULL,
  output        text,
  success       boolean DEFAULT true,
  mission_id    varchar,
  duration_ms   integer,
  created_at    timestamptz DEFAULT now()
);

CREATE INDEX IF NOT EXISTS idx_code_runs_user_created
  ON public.user_code_runs (user_id, created_at DESC);

-- 4) เซสชันแชท (จัดกลุ่มข้อความ)
CREATE TABLE IF NOT EXISTS public.chat_sessions (
  id          uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id     uuid NOT NULL REFERENCES public.users(id) ON DELETE CASCADE,
  title       varchar DEFAULT 'แชทใหม่',
  created_at  timestamptz DEFAULT now(),
  updated_at  timestamptz DEFAULT now()
);

-- ผูก chat_history กับ session
DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM information_schema.columns
    WHERE table_schema = 'public' AND table_name = 'chat_history' AND column_name = 'session_id'
  ) THEN
    ALTER TABLE public.chat_history ADD COLUMN session_id uuid REFERENCES public.chat_sessions(id) ON DELETE SET NULL;
  END IF;
END $$;

-- ============================================================
-- RLS
-- ============================================================
ALTER TABLE public.user_sandbox_files ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.user_code_runs ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.chat_sessions ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "sandbox_files_all_own" ON public.user_sandbox_files;
CREATE POLICY "sandbox_files_all_own" ON public.user_sandbox_files
  FOR ALL TO authenticated
  USING (user_id = auth.uid())
  WITH CHECK (user_id = auth.uid());

DROP POLICY IF EXISTS "code_runs_all_own" ON public.user_code_runs;
CREATE POLICY "code_runs_all_own" ON public.user_code_runs
  FOR ALL TO authenticated
  USING (user_id = auth.uid())
  WITH CHECK (user_id = auth.uid());

DROP POLICY IF EXISTS "chat_sessions_all_own" ON public.chat_sessions;
CREATE POLICY "chat_sessions_all_own" ON public.chat_sessions
  FOR ALL TO authenticated
  USING (user_id = auth.uid())
  WITH CHECK (user_id = auth.uid());

-- chat_history ควรมี policy อยู่แล้วจาก schema หลัก — สร้างซ้ำแบบ idempotent
DROP POLICY IF EXISTS "chat_history_all_own" ON public.chat_history;
CREATE POLICY "chat_history_all_own" ON public.chat_history
  FOR ALL TO authenticated
  USING (user_id = auth.uid())
  WITH CHECK (user_id = auth.uid());

-- ============================================================
-- Trigger อัปเดต updated_at ของไฟล์ sandbox
-- ============================================================
CREATE OR REPLACE FUNCTION public.set_updated_at()
RETURNS TRIGGER AS $$
BEGIN
  NEW.updated_at = now();
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

DROP TRIGGER IF EXISTS trg_sandbox_files_updated ON public.user_sandbox_files;
CREATE TRIGGER trg_sandbox_files_updated
  BEFORE UPDATE ON public.user_sandbox_files
  FOR EACH ROW EXECUTE FUNCTION public.set_updated_at();

DROP TRIGGER IF EXISTS trg_chat_sessions_updated ON public.chat_sessions;
CREATE TRIGGER trg_chat_sessions_updated
  BEFORE UPDATE ON public.chat_sessions
  FOR EACH ROW EXECUTE FUNCTION public.set_updated_at();
