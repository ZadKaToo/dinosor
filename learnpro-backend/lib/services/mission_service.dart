import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class MissionService {
  // เปลี่ยน IP ตามสภาพแวดล้อมของคุณ
  static const String baseUrl = 'http://127.0.0.1:3000/api/missions';

  static Future<Map<String, String>> _getHeaders() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token') ?? '';
    return {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer $token',
    };
  }

  /// 1. ดึงรายการภารกิจทั้งหมด (ใช้ในหน้าเลือกด่าน)
  static Future<List<dynamic>> getMissions({String? track}) async {
    try {
      final Uri uri = Uri.parse(baseUrl).replace(queryParameters: {
        if (track != null && track.isNotEmpty) 'track': track,
      });
      
      final response = await http.get(uri, headers: await _getHeaders());
      if (response.statusCode == 200) return jsonDecode(response.body);
    } catch (e) {
      print('Error fetching missions: $e');
    }
    return [];
  }

  /// 2. ดึงสถานะภารกิจของผู้ใช้ (ว่าด่านไหนผ่านแล้วบ้าง)
  static Future<List<dynamic>> getMyMissions() async {
    try {
      final response = await http.get(Uri.parse('$baseUrl/my'), headers: await _getHeaders());
      if (response.statusCode == 200) return jsonDecode(response.body);
    } catch (e) {
      print('Error fetching my missions: $e');
    }
    return [];
  }

  /// 3. ดึงรายละเอียดโจทย์ (โค้ดเริ่มต้น, คำอธิบาย ฯลฯ)
  static Future<Map<String, dynamic>?> getMissionDetail(String id) async {
    try {
      final response = await http.get(Uri.parse('$baseUrl/$id'), headers: await _getHeaders());
      if (response.statusCode == 200) return jsonDecode(response.body);
    } catch (e) {
      print('Error fetching mission detail: $e');
    }
    return null;
  }

  /// 4. ส่งผลการรันโค้ดไปให้ Backend (อัปเดต XP และสถานะ)
  static Future<Map<String, dynamic>?> submitMission(String id, String code, bool passed) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/$id/submit'),
        headers: await _getHeaders(),
        body: jsonEncode({
          'code': code,
          'passed': passed,
        }),
      );
      if (response.statusCode == 200) return jsonDecode(response.body);
    } catch (e) {
      print('Error submitting mission: $e');
    }
    return null;
  }
}