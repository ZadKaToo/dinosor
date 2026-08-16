import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// ย้ายจาก backend Node.js (127.0.0.1:3000/api/skills) มาคุยกับ Supabase โดยตรง
/// อ้างอิงตาราง public.skills_tags / user_skill_gaps / user_certified_skills
class SkillService {
  static final SupabaseClient _supabase = Supabase.instance.client;

  static String? get _userId => _supabase.auth.currentUser?.id;

  /// 1. ดึงรายชื่อทักษะทั้งหมด (Master Data) สำหรับให้ผู้ใช้ค้นหาหรือเลือก
  static Future<List<dynamic>> getSkillsTags() async {
    try {
      final result = await _supabase.from('skills_tags').select('*').order('name');
      return result;
    } catch (e) {
      debugPrint('Error fetching skills tags: $e');
      return [];
    }
  }

  /// 2. ดึงข้อมูลช่องว่างทักษะ (Skill Gaps) ของผู้ใช้ เรียงตามความเร่งด่วน
  static Future<List<dynamic>> getMySkillGaps() async {
    final userId = _userId;
    if (userId == null) return [];
    try {
      final result = await _supabase
          .from('user_skill_gaps')
          .select('urgency_score, is_acquired, skills_tags(id, name, category)')
          .eq('user_id', userId)
          .order('urgency_score', ascending: false);
      return (result as List)
          .map((row) {
            final skill = row['skills_tags'] as Map<String, dynamic>?;
            if (skill == null) return null;
            return {
              ...skill,
              'urgency_score': row['urgency_score'],
              'is_acquired': row['is_acquired'],
            };
          })
          .whereType<Map<String, dynamic>>()
          .toList();
    } catch (e) {
      debugPrint('Error fetching skill gaps: $e');
      return [];
    }
  }

  /// 3. ดึงใบรับรองทักษะ (Certified Skills / Badges) ที่ผู้ใช้ได้รับแล้ว
  static Future<List<dynamic>> getMyCertifiedSkills() async {
    final userId = _userId;
    if (userId == null) return [];
    try {
      final result = await _supabase
          .from('user_certified_skills')
          .select('*')
          .eq('user_id', userId)
          .order('certified_at', ascending: false);
      return result;
    } catch (e) {
      debugPrint('Error fetching certified skills: $e');
      return [];
    }
  }
}
