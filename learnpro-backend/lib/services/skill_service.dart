import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class SkillService {
  // สมมติว่าตั้งค่า Route ฝั่ง Backend เป็น /api/skills
  static const String baseUrl = 'http://127.0.0.1:3000/api/skills';

  static Future<Map<String, String>> _getHeaders() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token') ?? '';
    return {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer $token',
    };
  }

  /// 1. ดึงรายชื่อทักษะทั้งหมด (Master Data) สำหรับให้ผู้ใช้ค้นหาหรือเลือก
  static Future<List<dynamic>> getSkillsTags() async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/tags'), 
        headers: await _getHeaders()
      );
      if (response.statusCode == 200) return jsonDecode(response.body);
    } catch (e) {
      print('Error fetching skills tags: $e');
    }
    return [];
  }

  /// 2. ดึงข้อมูลช่องว่างทักษะ (Skill Gaps) ของผู้ใช้ เรียงตามความเร่งด่วน
  static Future<List<dynamic>> getMySkillGaps() async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/my-gaps'), 
        headers: await _getHeaders()
      );
      if (response.statusCode == 200) return jsonDecode(response.body);
    } catch (e) {
      print('Error fetching skill gaps: $e');
    }
    return [];
  }

  /// 3. ดึงใบรับรองทักษะ (Certified Skills / Badges) ที่ผู้ใช้ได้รับแล้ว
  static Future<List<dynamic>> getMyCertifiedSkills() async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/my-certified'), 
        headers: await _getHeaders()
      );
      if (response.statusCode == 200) return jsonDecode(response.body);
    } catch (e) {
      print('Error fetching certified skills: $e');
    }
    return [];
  }
}