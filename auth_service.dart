// ============================================================
// auth_service.dart
// "หลังบ้าน" (Backend Logic) สำหรับหน้า Login ธีมไดโนเสาร์
// ไฟล์นี้ทำหน้าที่ตรวจสอบ username / password
// ตอนนี้ใช้ "ข้อมูลทดลอง" (Mock Data) ไปก่อน
// ส่วนโค้ดสำหรับดึงข้อมูลจากฐานข้อมูลจริง ถูกคอมเม้นไว้ด้านล่าง
// ============================================================

// --------------------------------------------------------------
// ถ้าจะเชื่อมฐานข้อมูลจริงในอนาคต อาจต้อง import package เพิ่ม เช่น
// import 'package:http/http.dart' as http;
// import 'dart:convert';
// หรือถ้าใช้ฐานข้อมูลอื่น เช่น mysql1, postgres, firebase_auth
// ก็ import package ที่เกี่ยวข้องตรงนี้
// --------------------------------------------------------------

/// โมเดลข้อมูลผู้ใช้ (User) แบบง่าย ๆ
/// ใช้แทนข้อมูลที่ปกติจะได้มาจากฐานข้อมูล
class DinoUser {
  final String username;
  final String password;
  final String displayName;
  final String rank; // ยศ/ตำแหน่งในธีมไดโนเสาร์ เช่น "นักล่าฟอสซิล"

  const DinoUser({
    required this.username,
    required this.password,
    required this.displayName,
    required this.rank,
  });
}

/// ผลลัพธ์การ Login เพื่อให้หน้าบ้านเอาไปแสดงผลได้ง่าย ๆ
class LoginResult {
  final bool success;
  final String message;
  final DinoUser? user;

  const LoginResult({
    required this.success,
    required this.message,
    this.user,
  });
}

class AuthService {
  // ==========================================================
  // 🦴 ข้อมูลทดลอง (MOCK DATA)
  // ใช้แทนฐานข้อมูลจริงไปก่อน สามารถแก้ไข/เพิ่มผู้ใช้ทดสอบได้ที่นี่
  // ==========================================================
  static final List<DinoUser> _mockUsers = [
    const DinoUser(
      username: 'rex01',
      password: '1234',
      displayName: 'Tyrannosaurus Rex',
      rank: 'ราชาแห่งยุคครีเทเชียส',
    ),
    const DinoUser(
      username: 'trice',
      password: 'abcd',
      displayName: 'Triceratops',
      rank: 'นักรบสามเขา',
    ),
    const DinoUser(
      username: 'ptero',
      password: 'fly123',
      displayName: 'Pteranodon',
      rank: 'จ้าวเวหา',
    ),
  ];

  /// ฟังก์ชันสำหรับ Login
  /// ตอนนี้ใช้การเช็คกับ _mockUsers (ข้อมูลทดลอง)
  /// จำลอง delay เหมือนกำลังเรียก API จริง
  Future<LoginResult> login(String username, String password) async {
    // จำลองเวลาหน่วงเหมือนกำลังคุยกับ Server/Database จริง
    await Future.delayed(const Duration(milliseconds: 900));

    if (username.trim().isEmpty || password.trim().isEmpty) {
      return const LoginResult(
        success: false,
        message: 'กรุณากรอกชื่อผู้ใช้และรหัสผ่านให้ครบ 🦕',
      );
    }

    // ---------- ใช้ข้อมูลทดลองตรวจสอบ ----------
    final matched = _mockUsers.where(
      (u) => u.username == username && u.password == password,
    );

    if (matched.isNotEmpty) {
      return LoginResult(
        success: true,
        message: 'ยินดีต้อนรับกลับสู่ยุคไดโนเสาร์ 🦖',
        user: matched.first,
      );
    } else {
      return const LoginResult(
        success: false,
        message: 'ชื่อผู้ใช้หรือรหัสผ่านไม่ถูกต้อง กรุณาลองอีกครั้ง',
      );
    }

    // ==========================================================
    // 🗄️ โค้ดสำหรับเชื่อมต่อฐานข้อมูลจริง (คอมเม้นไว้ก่อน)
    // เมื่อพร้อมใช้งานจริง ให้ลบข้อความคอมเม้นด้านล่างออก
    // และลบ/ปิดส่วน mock data ด้านบนแทน
    // ==========================================================
    //
    // ตัวอย่างที่ 1: เชื่อมผ่าน REST API (backend เขียนแยกต่างหาก)
    // -----------------------------------------------------------
    // final response = await http.post(
    //   Uri.parse('https://your-api-domain.com/api/login'),
    //   headers: {'Content-Type': 'application/json'},
    //   body: jsonEncode({
    //     'username': username,
    //     'password': password,
    //   }),
    // );
    //
    // if (response.statusCode == 200) {
    //   final data = jsonDecode(response.body);
    //   return LoginResult(
    //     success: true,
    //     message: 'เข้าสู่ระบบสำเร็จ',
    //     user: DinoUser(
    //       username: data['username'],
    //       password: '', // ไม่ควรเก็บ password กลับมาแสดง
    //       displayName: data['display_name'],
    //       rank: data['rank'],
    //     ),
    //   );
    // } else {
    //   return const LoginResult(
    //     success: false,
    //     message: 'เข้าสู่ระบบไม่สำเร็จ กรุณาตรวจสอบข้อมูล',
    //   );
    // }
    //
    // ตัวอย่างที่ 2: เชื่อมฐานข้อมูล MySQL โดยตรง (เช่นใช้ package mysql1)
    // -----------------------------------------------------------
    // final conn = await MySqlConnection.connect(ConnectionSettings(
    //   host: 'your-db-host',
    //   port: 3306,
    //   user: 'db_user',
    //   password: 'db_password',
    //   db: 'dino_app',
    // ));
    //
    // final results = await conn.query(
    //   'SELECT * FROM users WHERE username = ? AND password = ?',
    //   [username, password],
    // );
    //
    // await conn.close();
    //
    // if (results.isNotEmpty) {
    //   final row = results.first;
    //   return LoginResult(
    //     success: true,
    //     message: 'เข้าสู่ระบบสำเร็จ',
    //     user: DinoUser(
    //       username: row['username'],
    //       password: '',
    //       displayName: row['display_name'],
    //       rank: row['rank'],
    //     ),
    //   );
    // } else {
    //   return const LoginResult(
    //     success: false,
    //     message: 'ชื่อผู้ใช้หรือรหัสผ่านไม่ถูกต้อง',
    //   );
    // }
    // ==========================================================
  }
}
