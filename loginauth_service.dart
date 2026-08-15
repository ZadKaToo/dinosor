import 'dart:convert';
import 'package:http/http.dart' as http;
import '../constants/app_constants.dart';

class AuthResult {
  final Map<String, dynamic> user;
  final String token;
  AuthResult({required this.user, required this.token});
}

class AuthException implements Exception {
  final String message;
  AuthException(this.message);
  @override
  String toString() => message;
}

class AuthService {
  static Uri _uri(String path) => Uri.parse('$kApiBaseUrl$path');

  static Future<AuthResult> login({required String email, required String password}) async {
    return _postAuth('/auth/login', {'email': email, 'password': password});
  }

  static Future<AuthResult> register({required String fullName, required String email, required String password}) async {
    return _postAuth('/auth/register', {'full_name': fullName, 'email': email, 'password': password});
  }

  static Future<AuthResult> _postAuth(String path, Map<String, dynamic> body) async {
    http.Response res;
    try {
      res = await http
          .post(_uri(path), headers: const {'Content-Type': 'application/json'}, body: jsonEncode(body))
          .timeout(const Duration(seconds: 15));
    } catch (_) {
      throw AuthException('เชื่อมต่อเซิร์ฟเวอร์ไม่ได้ กรุณาตรวจสอบอินเทอร์เน็ตหรือ URL ของ backend');
    }

    Map<String, dynamic> data;
    try {
      data = jsonDecode(res.body) as Map<String, dynamic>;
    } catch (_) {
      throw AuthException('เซิร์ฟเวอร์ตอบกลับไม่ถูกต้อง (${res.statusCode})');
    }

    if (res.statusCode < 200 || res.statusCode >= 300) {
      throw AuthException(data['error']?.toString() ?? 'เกิดข้อผิดพลาด กรุณาลองใหม่');
    }

    return AuthResult(user: data['user'] as Map<String, dynamic>, token: data['token'] as String);
  }
}
