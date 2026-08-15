import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../models/course_model.dart'; // ดึง Model มาใช้

class CourseService {
  static const String baseUrl = 'http://127.0.0.1:3000/api/courses';

  static Future<Map<String, String>> _getHeaders() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token') ?? '';
    return {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer $token',
    };
  }

  // 1. ปรับให้คืนค่าเป็น List<CourseModel>
  static Future<List<CourseModel>> getCourses({String? category}) async {
    try {
      String url = baseUrl;
      if (category != null && category.isNotEmpty) {
        url += '?category=$category';
      }

      final response = await http.get(Uri.parse(url), headers: await _getHeaders());

      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        return data.map((json) => CourseModel.fromJson(json)).toList();
      }
    } catch (e) {
      print('Error fetching courses: $e');
    }
    return [];
  }

  // 2. ดึงรายละเอียด (ใช้ Map<String, dynamic> เหมือนเดิมได้ เพราะข้อมูลอาจมี lessons ซ้อนอยู่)
  static Future<Map<String, dynamic>?> getCourseDetail(String id) async {
    try {
      final response = await http.get(Uri.parse('$baseUrl/$id'), headers: await _getHeaders());
      
      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      }
    } catch (e) {
      print('Error fetching course detail: $e');
    }
    return null;
  }

  // 3. บันทึกคอร์ส
  static Future<bool> saveCourse(String id) async {
    try {
      final response = await http.post(Uri.parse('$baseUrl/$id/save'), headers: await _getHeaders());
      return response.statusCode == 201;
    } catch (e) {
      print('Error saving course: $e');
      return false;
    }
  }
}