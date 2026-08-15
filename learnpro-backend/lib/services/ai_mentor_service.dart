import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class AiMentorService {
  // เปลี่ยน IP เป็นของเครื่องคุณ (ถ้าใช้ Emulator ให้ใช้ 10.0.2.2)
  static const String baseUrl = 'http://127.0.0.1:3000/api/mentor'; 

  static Future<Map<String, String>> _getHeaders() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token') ?? '';
    return {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer $token',
    };
  }

  /// 1. ดึงประวัติแชทเก่าจาก Database เมื่อเปิดหน้าจอ
  static Future<List<dynamic>> getChatHistory() async {
    try {
      // สมมติว่า Backend คุณตั้ง Route เป็น /api/mentor/history
      final response = await http.get(
        Uri.parse('$baseUrl/history'), 
        headers: await _getHeaders(),
      );

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        print('Error load history: ${response.statusCode}');
      }
    } catch (e) {
      print('Error fetching chat history: $e');
    }
    return [];
  }

  /// 2. ส่งข้อความใหม่ไปหา AI
  static Future<String?> sendMessage({
    required String message,
    required List<Map<String, String>> history,
  }) async {
    try {
      final response = await http.post(
        Uri.parse(baseUrl),
        headers: await _getHeaders(),
        body: jsonEncode({
          'message': message,
          'history': history,
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data['reply'];
      }
    } catch (e) {
      print('Error calling AI Mentor: $e');
    }
    return null;
  }
}