import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class JobService {
  // หากรันบน Android Emulator ใช้ 10.0.2.2 / หากรัน iOS หรือ Web ใช้ 127.0.0.1
  static const String baseUrl = 'http://127.0.0.1:3000/api/jobs';

  // ดึง Token สำหรับแนบไปกับ Request
  static Future<Map<String, String>> _getHeaders() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token') ?? '';
    return {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer $token',
    };
  }

  /// 1. ดึงรายการงานทั้งหมด (สามารถส่ง category หรือ experience ไปกรองได้)
  static Future<List<dynamic>> getJobs({String? category, String? experience}) async {
    try {
      // สร้าง URL และจัดการ Query Parameters
      final Uri uri = Uri.parse(baseUrl).replace(queryParameters: {
        if (category != null && category.isNotEmpty) 'category': category,
        if (experience != null && experience.isNotEmpty) 'experience': experience,
      });

      final response = await http.get(uri, headers: await _getHeaders());

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        print('Failed to load jobs. Status: ${response.statusCode}');
      }
    } catch (e) {
      print('Error fetching jobs: $e');
    }
    return [];
  }

  /// 2. ดึงรายละเอียดงานพร้อม Required Skills
  static Future<Map<String, dynamic>?> getJobDetail(String id) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/$id'),
        headers: await _getHeaders(),
      );

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        print('Failed to load job detail. Status: ${response.statusCode}');
      }
    } catch (e) {
      print('Error fetching job detail: $e');
    }
    return null;
  }
}