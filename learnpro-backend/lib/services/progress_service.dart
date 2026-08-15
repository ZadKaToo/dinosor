import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class ProgressService {
  // เปลี่ยน IP ตามสภาพแวดล้อมที่รันทดสอบ
  static const String baseUrl = 'http://127.0.0.1:3000/api/progress';

  static Future<Map<String, String>> _getHeaders() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token') ?? '';
    return {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer $token',
    };
  }

  /// 1. ดึงข้อมูลความคืบหน้า (XP, Streak, Run Count และ Badges ทั้งหมด)
  static Future<Map<String, dynamic>?> getMyProgress() async {
    try {
      final response = await http.get(Uri.parse(baseUrl), headers: await _getHeaders());
      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      }
    } catch (e) {
      print('Error fetching progress: $e');
    }
    return null;
  }

  /// 2. เพิ่ม XP (Backend จะคำนวณ Streak Multiplier และแจก Badge ให้เอง)
  static Future<Map<String, dynamic>?> addXp(int amount) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/xp'),
        headers: await _getHeaders(),
        body: jsonEncode({'amount': amount}),
      );
      if (response.statusCode == 200) {
        return jsonDecode(response.body); // คืนค่า gained, total_xp, streak_days, run_count
      }
    } catch (e) {
      print('Error adding XP: $e');
    }
    return null;
  }

  /// 3. เพิ่มจำนวนครั้งที่รันโค้ด (เรียกใช้เมื่อกดรันโค้ดใน Sandbox)
  static Future<Map<String, dynamic>?> incrementRunCount() async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/run'),
        headers: await _getHeaders(),
      );
      if (response.statusCode == 200) {
        return jsonDecode(response.body); // คืนค่า run_count ล่าสุด
      }
    } catch (e) {
      print('Error incrementing run count: $e');
    }
    return null;
  }
}