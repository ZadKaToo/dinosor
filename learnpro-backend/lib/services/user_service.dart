import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class UserService {
  // เปลี่ยน IP ตามสภาพแวดล้อมที่รันทดสอบ
  static const String baseUrl = 'http://127.0.0.1:3000/api';

  static Future<Map<String, String>> _getHeaders() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token') ?? '';
    return {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer $token',
    };
  }

  /// 1. ดึงข้อมูล User Profile (ข้อมูลผู้ใช้ที่ล็อกอินอยู่)
  static Future<Map<String, dynamic>?> getMyProfile() async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/auth/me'), // ชี้ไปที่ Endpoint ข้อมูล User ของคุณ
        headers: await _getHeaders(),
      );

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      }
    } catch (e) {
      print('Error fetching profile: $e');
    }
    return null;
  }

  /// 2. อัปเดตข้อมูลโปรไฟล์ผู้ใช้
  static Future<Map<String, dynamic>?> updateProfile({
    String? fullName,
    String? avatarUrl,
    String? targetRole,
    String? bio,
    String? phone,
  }) async {
    try {
      final response = await http.put(
        Uri.parse('$baseUrl/users/profile'),
        headers: await _getHeaders(),
        body: jsonEncode({
          if (fullName != null) 'full_name': fullName,
          if (avatarUrl != null) 'avatar_url': avatarUrl,
          if (targetRole != null) 'target_role': targetRole,
          if (bio != null) 'bio': bio,
          if (phone != null) 'phone': phone,
        }),
      );

      if (response.statusCode == 200) return jsonDecode(response.body);
    } catch (e) {
      print('Error updating profile: $e');
    }
    return null;
  }

  /// 3. ดึงข้อมูลการตั้งค่าของผู้ใช้
  static Future<Map<String, dynamic>?> getSettings() async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/users/settings'),
        headers: await _getHeaders(),
      );

      if (response.statusCode == 200) return jsonDecode(response.body);
    } catch (e) {
      print('Error fetching settings: $e');
    }
    return null;
  }

  /// 4. อัปเดตการตั้งค่า (แจ้งเตือน, ธีมสี, ภาษา)
  static Future<Map<String, dynamic>?> updateSettings({
    bool? pushNotifications,
    bool? darkMode,
    String? language,
  }) async {
    try {
      final response = await http.put(
        Uri.parse('$baseUrl/users/settings'),
        headers: await _getHeaders(),
        body: jsonEncode({
          if (pushNotifications != null) 'push_notifications': pushNotifications,
          if (darkMode != null) 'dark_mode': darkMode,
          if (language != null) 'language': language,
        }),
      );

      if (response.statusCode == 200) return jsonDecode(response.body);
    } catch (e) {
      print('Error updating settings: $e');
    }
    return null;
  }
}