import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// ย้ายจาก backend Node.js (127.0.0.1:3000/api) มาคุยกับ Supabase โดยตรง
/// อ้างอิงตาราง public.quizzes
class QuizService {
  static final SupabaseClient _supabase = Supabase.instance.client;

  /// 1. ดึงรายการแบบทดสอบทั้งหมดในคอร์สนั้น (ไม่ส่ง correct_answer_index กลับไปให้ UI
  /// เพื่อไม่ให้เฉลยหลุดไปฝั่ง client ก่อนตอบ)
  static Future<List<dynamic>> getCourseQuizzes(String courseId) async {
    try {
      final result = await _supabase
          .from('quizzes')
          .select('id, course_id, lesson_order, question, option_1, option_2, option_3, option_4')
          .eq('course_id', courseId)
          .order('lesson_order');
      return result;
    } catch (e) {
      debugPrint('Error fetching quizzes: $e');
      return [];
    }
  }

  /// 2. ตรวจคำตอบ — ดึงเฉลยจริงจากตารางมาตรวจฝั่งนี้ (RLS ควรจำกัดไม่ให้ select
  /// correct_answer_index ได้ตามปกติ แนะนำให้ทำเป็น Postgres function/RPC
  /// สำหรับ production จริงเพื่อไม่ให้เฉลยรั่วผ่าน network request)
  static Future<Map<String, dynamic>?> answerQuiz(String quizId, int selectedIndex) async {
    try {
      final quiz = await _supabase
          .from('quizzes')
          .select('correct_answer_index, explanation')
          .eq('id', quizId)
          .maybeSingle();
      if (quiz == null) return null;

      final correctIndex = quiz['correct_answer_index'] as int;
      return {
        'correct': selectedIndex == correctIndex,
        'correct_answer_index': correctIndex,
        'explanation': quiz['explanation'],
      };
    } catch (e) {
      debugPrint('Error submitting quiz answer: $e');
      return null;
    }
  }
}
