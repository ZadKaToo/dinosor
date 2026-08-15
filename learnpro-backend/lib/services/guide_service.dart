import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class GuideService {
  // เปลี่ยน IP ตามสภาพแวดล้อมที่รันทดสอบ (เช่น 10.0.2.2 สำหรับ Android Emulator)
  static const String baseUrl = 'http://127.0.0.1:3000/api/guides';

  // ดึง Token จาก SharedPreferences เพื่อส่งไปยืนยันตัวตน
  static Future<Map<String, String>> _getHeaders() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token') ?? '';
    return {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer $token',
    };
  }

  /// 1. ดึงรายการบทความทั้งหมด หรือดึงตามหมวดหมู่ (ตรงกับฟังก์ชัน listGuides)
  static Future<List<dynamic>> getGuides({String? category}) async {
    try {
      String url = baseUrl;
      if (category != null && category.isNotEmpty) {
        // แปะ Query parameter ?category=... ส่งไปให้ Backend
        url += '?category=$category';
      }

      final response = await http.get(Uri.parse(url), headers: await _getHeaders());

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        print('Failed to load guides. Status: ${response.statusCode}');
      }
    } catch (e) {
      print('Error fetching guides: $e');
    }
    return [];
  }

  /// 2. ดึงรายละเอียดบทความ 1 เรื่อง (ตรงกับฟังก์ชัน getGuide)
  /// Backend จะทำการ +1 views_count ให้อัตโนมัติเมื่อเรียก API นี้
  static Future<Map<String, dynamic>?> getGuideDetail(String id) async {
    try {
      final response = await http.get(Uri.parse('$baseUrl/$id'), headers: await _getHeaders());

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        print('Failed to load guide detail. Status: ${response.statusCode}');
      }
    } catch (e) {
      print('Error fetching guide detail: $e');
    }
    return null;
  }
}