import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class AuthService {
  // เปลี่ยนเป็น URL ของ Backend คุณ (ถ้ารันผ่าน Emulator ใช้ 10.0.2.2)
  static const String baseUrl = 'http://127.0.0.1:3000/api/auth';

  // ฟังก์ชัน Login
  static Future<bool> login(String email, String password) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/login'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'email': email,
          'password': password,
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final token = data['token'];
        
        // บันทึก Token ลงในเครื่อง
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('token', token);
        return true;
      } else {
        print('Login failed: ${response.body}');
        return false;
      }
    } catch (e) {
      print('Error during login: $e');
      return false;
    }
  }

  // ฟังก์ชันดึง Token มาใช้ใน Service อื่นๆ
  static Future<String?> getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('token');
  }

  // ฟังก์ชัน Logout
  static Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('token');
  }

  // เช็คว่าเคย Login ไว้หรือยัง (ใช้ตอนเปิดแอป)
  static Future<bool> isLoggedIn() async {
    final token = await getToken();
    return token != null && token.isNotEmpty;
  }

  // --- ฟังก์ชันที่เพิ่มใหม่: สมัครสมาชิก ---
  static Future<bool> register(String fullName, String email, String password) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/register'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'full_name': fullName, // ปรับคีย์ให้ตรงกับที่ Backend คุณรอรับ
          'email': email,
          'password': password,
        }),
      );

      // ปกติ API สร้างข้อมูลใหม่มักจะตอบ 201 Created หรือ 200 OK
      if (response.statusCode == 200 || response.statusCode == 201) {
        return true;
      } else {
        print('Register failed: ${response.body}');
        return false;
      }
    } catch (e) {
      print('Error during register: $e');
      return false;
    }
  }
  
}