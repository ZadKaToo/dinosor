import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class AuthService {
  static final SupabaseClient _supabase = Supabase.instance.client;

  /// สร้างแถวใน public.users ให้ตรงกับ auth.users ปัจจุบัน ถ้ายังไม่มี
  /// ใช้ ignoreDuplicates:true เพื่อไม่ชนกับ DB trigger (ถ้ามี) ที่อาจสร้างแถวนี้ไว้ก่อนแล้ว
  /// เรียกได้ทั้งตอน register (ถ้ามี session ทันที) และตอน login (เผื่อกรณี confirm
  /// email ทำให้ตอน register ยังไม่มี session พอจะ insert ผ่าน RLS ได้)
  static Future<void> _ensureProfileRow(User user) async {
    try {
      final fullName = (user.userMetadata?['full_name'] as String?)?.trim();
      final targetRole = (user.userMetadata?['target_role'] as String?)?.trim();
      await _supabase.from('users').upsert(
        {
          'id': user.id,
          'email': user.email ?? '',
          'full_name': (fullName == null || fullName.isEmpty) ? 'ผู้ใช้งาน' : fullName,
          if (targetRole != null && targetRole.isNotEmpty) 'target_role': targetRole,
          'created_at': DateTime.now().toIso8601String(),
        },
        onConflict: 'id',
        ignoreDuplicates: true,
      );
    } catch (e) {
      // ไม่ถือเป็น error ร้ายแรง — บัญชี auth ยังใช้งานได้ปกติ แถวโปรไฟล์จะถูก
      // สร้างซ้ำอีกครั้งในครั้งถัดไปที่ login สำเร็จ (เผื่อครั้งนี้ถูก RLS บล็อกเพราะ
      // ยังไม่ได้ confirm email เลยไม่มี session ตอนเรียก)
      debugPrint('Ensure profile row skipped/failed: $e');
    }
  }

  /// เข้าสู่ระบบ
  static Future<String?> login(String email, String password) async {
    try {
      final response = await _supabase.auth.signInWithPassword(
        email: email,
        password: password,
      );
      if (response.session == null) return 'ไม่พบ Session การเข้าใช้งาน';

      // ตอนนี้มี session แน่นอนแล้ว เผื่อโปรไฟล์ยังไม่เคยถูกสร้าง (เช่น register
      // ครั้งก่อนถูก RLS บล็อกเพราะยังไม่ confirm email ตอนนั้น) ให้สร้างให้ตอนนี้เลย
      final user = response.user;
      if (user != null) await _ensureProfileRow(user);

      return null;
    } on AuthException catch (e) {
      debugPrint('Login AuthException: ${e.message}');
      return e.message;
    } catch (e) {
      debugPrint('Login Unknown Error: $e');
      return 'เกิดข้อผิดพลาดในการเชื่อมต่อ: $e';
    }
  }

  /// สมัครสมาชิกและบันทึกลงตาราง users
  /// [targetRole] คือ track id ที่ผู้ใช้เลือกตอนสมัคร (เช่น 'swe', 'data', 'devops', 'sec'
  /// ตรงกับ track ในหน้า ITTracksScreen) ใส่หรือไม่ใส่ก็ได้ (optional)
  static Future<String?> register(
    String fullName,
    String email,
    String password, {
    String? targetRole,
  }) async {
    try {
      // 1. สร้างบัญชีในระบบ Authentication ของ Supabase
      // ฝากชื่อ + สายงานที่เลือกไว้ใน user metadata ด้วย — ส่วนนี้บันทึกสำเร็จเสมอไม่ว่าจะ
      // เปิด/ปิด "Confirm email" ไว้หรือไม่ ต่างจากการ insert ลงตาราง users ด้านล่างที่อาจ
      // โดน RLS บล็อกถ้ายังไม่มี session (กรณีเปิด confirm email)
      final response = await _supabase.auth.signUp(
        email: email,
        password: password,
        data: {
          'full_name': fullName,
          if (targetRole != null && targetRole.isNotEmpty) 'target_role': targetRole,
        },
      );

      final user = response.user;
      if (user == null) return 'ไม่สามารถสร้างบัญชีผู้ใช้ได้';

      // 2. บันทึกข้อมูลลงตาราง "users" แบบ best-effort
      // หมายเหตุ: ตาราง users ใน schema ไม่มีคอลัมน์ password_hash (Supabase Auth
      // เก็บรหัสผ่านแยกไว้ในระบบ auth.users อยู่แล้ว) จึงไม่ต้องส่งค่านี้ไปด้วย
      // ถ้าขั้นตอนนี้ล้มเหลว (เช่นยังไม่มี session เพราะรอ confirm email) จะไม่ถือว่า
      // register ล้มเหลว เพราะ _ensureProfileRow ใน login() จะสร้างแถวนี้ให้อีกครั้ง
      await _ensureProfileRow(user);

      return null; // สำเร็จ ไม่มี Error
    } on AuthException catch (e) {
      debugPrint('Register AuthException: ${e.message}');
      return e.message;
    } catch (e) {
      debugPrint('Register Unknown Error: $e');
      return 'เกิดข้อผิดพลาดในการบันทึกข้อมูล: $e';
    }
  }

  static Future<void> logout() async {
    await _supabase.auth.signOut();
  }
}
