import 'package:supabase_flutter/supabase_flutter.dart';

/// เชื่อมต่อ AI Mentor ผ่าน Supabase Edge Function โดยตรง (function name: "mentor")
/// นี่คือ backend จริงที่ใช้งานอยู่ (ตัวเดียวกับที่ initialize ไว้ใน main.dart และ
/// ใช้ใน auth_service.dart) — ไม่ใช่ Node/Express server บน 127.0.0.1:4000 ซึ่งเป็นคนละ
/// เส้นทาง และเป็นสาเหตุที่ก่อนหน้านี้เจอ "connection refused" (ไม่มีอะไรรันอยู่ที่พอร์ตนั้น)
class AiMentorService {
  static final SupabaseClient _supabase = Supabase.instance.client;

  /// คืน user id ของบัญชีที่ login ผ่าน Supabase Auth เท่านั้น
  /// (ไม่มี fallback เป็น anonymous id อีกต่อไป — บังคับต้อง login ก่อนถึงจะแชทได้
  /// และต้องมีข้อมูลผู้ใช้ เช่น full_name อยู่ในตาราง users แล้ว เพราะขั้นตอนสมัครสมาชิก
  /// ใน auth_service.dart บันทึก full_name ไว้ตั้งแต่ตอน register)
  static String _requireUserId() {
    final currentUser = _supabase.auth.currentUser;
    if (currentUser == null) {
      throw Exception('กรุณาเข้าสู่ระบบก่อนใช้งาน AI Mentor');
    }
    return currentUser.id;
  }

  /// ส่งข้อความไปหา AI Mentor ผ่าน Edge Function
  /// โยน Exception ออกไปเมื่อเกิด error เพื่อให้ UI แสดงข้อความที่ชัดเจนแก่ผู้ใช้
  static Future<String> sendMessage(String message) async {
    final userId = _requireUserId(); // โยน Exception ทันทีถ้ายังไม่ login ไม่ต้องเข้า try/catch ด้านล่าง

    try {
      final response = await _supabase.functions.invoke(
        'mentor',
        body: {
          'message': message,
          'user_id': userId,
        },
      );

      final data = response.data;
      if (data is Map) {
        final reply = data['reply'] ?? data['message'];
        if (reply != null) return reply.toString();
      }
      return 'ไม่มีข้อมูลตอบกลับ';
    } on FunctionException catch (e) {
      throw Exception('AI Mentor ตอบกลับผิดพลาด (${e.status}): ${e.details ?? e.reasonPhrase ?? ''}');
    } catch (e) {
      throw Exception('ไม่สามารถเชื่อมต่อกับเซิร์ฟเวอร์ได้: $e');
    }
  }
}
