import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class QuizService {
  // สมมติว่าตั้งค่า Route ฝั่ง Backend ไว้ตามนี้ (สามารถเปลี่ยนให้ตรงกับที่คุณตั้งไว้ใน routes.js ได้เลย)
  static const String apiBaseUrl = 'http://127.0.0.1:3000/api';

  static Future<Map<String, String>> _getHeaders() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token') ?? '';
    return {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer $token',
    };
  }

  /// 1. ดึงรายการแบบทดสอบทั้งหมดในคอร์สนั้น (ข้อมูลที่ได้จะไม่มีเฉลย)
  static Future<List<dynamic>> getCourseQuizzes(String courseId) async {
    try {
      // ตัวอย่าง URL: /api/courses/:id/quizzes
      final response = await http.get(
        Uri.parse('$apiBaseUrl/courses/$courseId/quizzes'),
        headers: await _getHeaders(),
      );

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        print('Failed to load quizzes. Status: ${response.statusCode}');
      }
    } catch (e) {
      print('Error fetching quizzes: $e');
    }
    return [];
  }

  /// 2. ส่งคำตอบไปตรวจกับ Backend
  static Future<Map<String, dynamic>?> answerQuiz(String quizId, int selectedIndex) async {
    try {
      // ตัวอย่าง URL: /api/quizzes/:id/answer
      final response = await http.post(
        Uri.parse('$apiBaseUrl/quizzes/$quizId/answer'),
        headers: await _getHeaders(),
        body: jsonEncode({
          'selected_index': selectedIndex,
        }),
      );

      if (response.statusCode == 200) {
        // Backend จะคืนค่า { correct: boolean, correct_answer_index: int, explanation: string }
        return jsonDecode(response.body);
      } else {
        print('Failed to submit answer. Status: ${response.statusCode}');
      }
    } catch (e) {
      print('Error submitting quiz answer: $e');
    }
    return null;
  }
}