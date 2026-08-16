import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/course_model.dart';

/// ย้ายจาก backend Node.js (127.0.0.1:3000/api/courses) มาคุยกับ Supabase โดยตรง
/// อ้างอิงตาราง public.courses / course_skills / course_lessons / saved_courses
class CourseService {
  static final SupabaseClient _supabase = Supabase.instance.client;

  static String? get _userId => _supabase.auth.currentUser?.id;

  /// 1. ดึงรายการคอร์สทั้งหมด หรือกรองตามหมวดหมู่
  static Future<List<CourseModel>> getCourses({String? category}) async {
    try {
      var query = _supabase.from('courses').select('*');
      if (category != null && category.isNotEmpty) {
        query = query.eq('category', category);
      }
      final result = await query.order('created_at', ascending: false);
      return (result as List)
          .map((row) => CourseModel.fromJson(row as Map<String, dynamic>))
          .toList();
    } catch (e) {
      debugPrint('Error fetching courses: $e');
      return [];
    }
  }

  /// 2. ดึงรายละเอียดคอร์ส พร้อม lessons และ required skills ที่เกี่ยวข้อง
  static Future<Map<String, dynamic>?> getCourseDetail(String id) async {
    try {
      final course = await _supabase.from('courses').select('*').eq('id', id).maybeSingle();
      if (course == null) return null;

      final lessons = await _supabase
          .from('course_lessons')
          .select('*')
          .eq('course_id', id)
          .order('order_index');

      final skillLinks = await _supabase
          .from('course_skills')
          .select('skills_tags(id, name, category)')
          .eq('course_id', id);
      final skills = (skillLinks as List)
          .map((row) => row['skills_tags'])
          .whereType<Map<String, dynamic>>()
          .toList();

      return {...course, 'lessons': lessons, 'skills': skills};
    } catch (e) {
      debugPrint('Error fetching course detail: $e');
      return null;
    }
  }

  /// 3. บันทึกคอร์ส (saved_courses) ให้ผู้ใช้ที่ login อยู่
  static Future<bool> saveCourse(String id) async {
    final userId = _userId;
    if (userId == null) return false;
    try {
      await _supabase.from('saved_courses').upsert(
        {'user_id': userId, 'course_id': id},
        onConflict: 'user_id,course_id',
        ignoreDuplicates: true,
      );
      return true;
    } catch (e) {
      debugPrint('Error saving course: $e');
      return false;
    }
  }

  /// 4. ยกเลิกบันทึกคอร์ส
  static Future<bool> unsaveCourse(String id) async {
    final userId = _userId;
    if (userId == null) return false;
    try {
      await _supabase.from('saved_courses').delete().eq('user_id', userId).eq('course_id', id);
      return true;
    } catch (e) {
      debugPrint('Error unsaving course: $e');
      return false;
    }
  }

  /// 5. ดึงคอร์สที่บันทึกไว้ทั้งหมดของผู้ใช้
  static Future<List<CourseModel>> getSavedCourses() async {
    final userId = _userId;
    if (userId == null) return [];
    try {
      final result = await _supabase
          .from('saved_courses')
          .select('courses(*)')
          .eq('user_id', userId)
          .order('saved_at', ascending: false);
      return (result as List)
          .map((row) => row['courses'])
          .whereType<Map<String, dynamic>>()
          .map((c) => CourseModel.fromJson(c))
          .toList();
    } catch (e) {
      debugPrint('Error fetching saved courses: $e');
      return [];
    }
  }
}
