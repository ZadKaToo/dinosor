const supabase = require('../config/supabase');

// 1. โปรไฟล์ (Profile)
exports.getProfile = async (req, res) => {
  try {
    const { data, error } = await supabase
      .from('users')
      // ดึงข้อมูลส่วนตัว พร้อมชื่อสายอาชีพที่เลือกไว้ (Join ตาราง career_tracks)
      .select('id, email, full_name, created_at, career_tracks(title)')
      .eq('id', req.user.id)
      .single();

    if (error) throw error;
    res.json(data);
  } catch (error) {
    res.status(500).json({ error: error.message });
  }
};

// 2. ประวัติการฝึกหลักสูตร (Training/course history)
exports.getHistory = async (req, res) => {
  try {
    const { data, error } = await supabase
      .from('user_course_history')
      // ดึงประวัติ พร้อมรายละเอียดคอร์สที่กำลังเรียนอยู่
      .select('status, progress_percent, last_accessed, courses(id, title, thumbnail_url)')
      .eq('user_id', req.user.id)
      .order('last_accessed', { ascending: false });

    if (error) throw error;
    res.json(data);
  } catch (error) {
    res.status(500).json({ error: error.message });
  }
};

// 3. หลักสูตรที่เลือกไว้ / บันทึกไว้ (Saved/selected courses)
exports.getSavedCourses = async (req, res) => {
  try {
    const { data, error } = await supabase
      .from('saved_courses')
      .select('saved_at, courses(id, title, thumbnail_url, max_potential_salary)')
      .eq('user_id', req.user.id)
      .order('saved_at', { ascending: false });

    if (error) throw error;
    res.json(data);
  } catch (error) {
    res.status(500).json({ error: error.message });
  }
};

// 5. ดึงข้อมูลการตั้งค่า (Settings)
exports.getSettings = async (req, res) => {
  try {
    const { data, error } = await supabase
      .from('user_settings')
      .select('push_notifications, dark_mode, language')
      .eq('user_id', req.user.id)
      .single();

    if (error) throw error;
    res.json(data);
  } catch (error) {
    res.status(500).json({ error: error.message });
  }
};

// 5.1 อัปเดตการตั้งค่า (Update Settings)
exports.updateSettings = async (req, res) => {
  try {
    const { push_notifications, dark_mode, language } = req.body;
    
    const { data, error } = await supabase
      .from('user_settings')
      .update({ push_notifications, dark_mode, language })
      .eq('user_id', req.user.id)
      .select()
      .single();

    if (error) throw error;
    res.json({ message: 'อัปเดตการตั้งค่าสำเร็จ', data });
  } catch (error) {
    res.status(500).json({ error: error.message });
  }
};