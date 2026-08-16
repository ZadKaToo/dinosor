import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// ย้ายจากการยิง REST ไปที่ backend Node.js (127.0.0.1:3000) มาคุยกับ Supabase
/// โดยตรงทั้งหมด — ไม่ต้องรัน server แยกอีกต่อไป
class UserService {
  static final SupabaseClient _supabase = Supabase.instance.client;

  static String? get _currentUserId => _supabase.auth.currentUser?.id;

  /// 1. ดึงข้อมูล User Profile (ข้อมูลผู้ใช้ที่ล็อกอินอยู่)
  static Future<Map<String, dynamic>?> getMyProfile() async {
    final userId = _currentUserId;
    if (userId == null) return null;
    try {
      final response = await _supabase
          .from('users')
          .select('*')
          .eq('id', userId)
          .maybeSingle();
      return response;
    } catch (e) {
      debugPrint('Error fetching profile: $e');
      return null;
    }
  }

  /// 2. อัปเดตข้อมูลโปรไฟล์ผู้ใช้
  static Future<Map<String, dynamic>?> updateProfile({
    String? fullName,
    String? avatarUrl,
    String? targetRole,
    String? bio,
    String? phone,
  }) async {
    final userId = _currentUserId;
    if (userId == null) return null;
    try {
      final Map<String, dynamic> updates = {};
      if (fullName != null) updates['full_name'] = fullName;
      if (avatarUrl != null) updates['avatar_url'] = avatarUrl;
      if (targetRole != null) updates['target_role'] = targetRole;
      if (bio != null) updates['bio'] = bio;
      if (phone != null) updates['phone'] = phone;
      if (updates.isEmpty) return null;

      final response = await _supabase
          .from('users')
          .update(updates)
          .eq('id', userId)
          .select()
          .maybeSingle();
      return response;
    } catch (e) {
      debugPrint('Error updating profile: $e');
      return null;
    }
  }

  /// 3. ดึงข้อมูลการตั้งค่าของผู้ใช้
  static Future<Map<String, dynamic>?> getSettings() async {
    final userId = _currentUserId;
    if (userId == null) return null;
    try {
      final response = await _supabase
          .from('user_settings')
          .select('*')
          .eq('user_id', userId)
          .maybeSingle();
      return response;
    } catch (e) {
      debugPrint('Error fetching settings: $e');
      return null;
    }
  }

  /// 4. อัปเดตการตั้งค่า (แจ้งเตือน, ธีมสี, ภาษา)
  /// ใช้ upsert เผื่อยังไม่เคยมีแถวใน user_settings มาก่อน
  static Future<Map<String, dynamic>?> updateSettings({
    bool? pushNotifications,
    bool? darkMode,
    String? language,
  }) async {
    final userId = _currentUserId;
    if (userId == null) return null;
    try {
      final Map<String, dynamic> updates = {'user_id': userId};
      if (pushNotifications != null) updates['push_notifications'] = pushNotifications;
      if (darkMode != null) updates['dark_mode'] = darkMode;
      if (language != null) updates['language'] = language;

      final response = await _supabase
          .from('user_settings')
          .upsert(updates)
          .select()
          .maybeSingle();
      return response;
    } catch (e) {
      debugPrint('Error updating settings: $e');
      return null;
    }
  }
}
