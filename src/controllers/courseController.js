const supabase = require('../config/supabase');

exports.getFeed = async (req, res) => {
  try {
    const userId = req.user.id;

    // 1. ดึงข้อมูล User เพื่อดูว่ามีการเลือกสายอาชีพไว้หรือไม่ (อาจเป็น null)
    const { data: user, error: userError } = await supabase
      .from('users')
      .select('career_track_id')
      .eq('id', userId)
      .single();

    if (userError) throw userError;

    // 2. ดึงข้อมูลคอร์สเรียนทั้งหมด (ปรับฟิลด์ให้ตรงกับ Database Schema)
    // ใช้ cover_image_url แทน thumbnail_url และเพิ่ม summary สำหรับหน้า Feed
    let { data: courses, error: courseError } = await supabase
      .from('courses')
      .select(`
        id, 
        title, 
        summary, 
        cover_image_url, 
        max_potential_salary, 
        difficulty_level,
        estimated_read_time_mins,
        like_count,
        share_count,
        created_at,
        career_track_id,
        career_tracks (title)
      `)
      // เรียงลำดับเริ่มต้นจากเงินเดือนสูงสุดลงมา
      .order('max_potential_salary', { ascending: false });

    if (courseError) throw courseError;

    // 3. จัดลำดับหน้า Feed (Algorithm)
    // ถ้าผู้ใช้มี career_track_id ให้ดันคอร์สที่ตรงกับสายอาชีพขึ้นมาอยู่บนสุด
    if (user && user.career_track_id) {
      courses = courses.sort((a, b) => {
        // ถ้า a ตรงกับสายอาชีพ แต่ b ไม่ตรง -> ดัน a ขึ้นไป
        if (a.career_track_id === user.career_track_id && b.career_track_id !== user.career_track_id) return -1;
        // ถ้า b ตรงกับสายอาชีพ แต่ a ไม่ตรง -> ดัน b ขึ้นไป
        if (a.career_track_id !== user.career_track_id && b.career_track_id === user.career_track_id) return 1;
        // ถ้าตรงทั้งคู่ หรือไม่ตรงทั้งคู่ ให้คงลำดับเดิมไว้ (ซึ่งเรียงตาม max_potential_salary อยู่แล้ว)
        return 0;
      });
    }

    // 4. ส่งข้อมูลกลับไปให้ Mobile App
    res.status(200).json({ 
      message: 'ดึงข้อมูลหน้า Feed สำเร็จ', 
      total: courses.length,
      data: courses 
    });

  } catch (error) {
    console.error('Get Feed Error:', error);
    res.status(500).json({ error: error.message });
  }
};